module EasyContacts
  module Carddav
    class Controller < EasyExtensions::Webdav::Controller

      NAMESPACES = NAMESPACES.merge(
        'xmlns:cs'   => 'http://calendarserver.org/ns/',
        'xmlns:card' => 'urn:ietf:params:xml:ns:carddav'
      )

      PROP_NAMESPACES = PROP_NAMESPACES.merge(
        'getctag' => 'cs',
        'address-data' => 'card',
        'addressbook-home-set' => 'card'
      )

      def resource_class
        case path_info
        when '/'
          AddressBooksResource

        when '/principal'
          PrincipalResource

        when '/easy_contact'
          EasyContactsResource

        when '/users', /\A\/users_q\d+\Z/
          UsersResource

        when /\A\/easy_contact\/[^\/]+\Z/
          case request_method
          when :get, :put, :delete
            EasyContactResource
          else
            EasyContactsResource
          end

        when /\A\/users(_q\d+)?\/[^\/]+\Z/
          case request_method
          when :get
            UserResource
          else
            UsersResource
          end
        end
      end


      # HTTP Requests
      # =======================================================================

      # == Not supported:
      # props::
      #   address_data specific values
      # filters::
      #   card:param-filter
      #   card:is-not-defined
      #
      def report
        # All requested properties
        props = request_match("//d:prop/*").map(&:name)

        # Custom columns
        # address_data = request_match('//d:prop/card:address-data/card:prop/@name').map(&:value)

        # Get report resources
        report_data =
          case request_body.root.name

          when 'addressbook-query'
            # Filters
            filters = {}
            filters_data = request_match('/card:addressbook-query/card:filter')
            if filters_data.any?
              filters[:test] = filters_data.first['test'] || 'anyof'
              filters[:props] = []

              prop_filters = match(filters_data, '/card:prop-filter')
              prop_filters.each do |prop_filter|
                _prop = {}
                _prop[:name] = prop_filter['name']
                _prop[:test] = prop_filter['test'] || 'anyof'
                _prop[:matches] = []

                text_matches = match(prop_filter, '/card:text-match')
                text_matches.each do |text_match|
                  _match = {}
                  _match[:collation] = text_match['collation'] || 'i;unicode-casemap'
                  _match[:type] = text_match['match-type'] || 'contains'
                  _match[:negate] = text_match['negate-condition'] || 'no'
                  _match[:text] = text_match.text.to_s

                  _prop[:matches] << _match
                end

                filters[:props] << _prop
              end
            end

            resource.report_query(filters)

          when 'addressbook-multiget'
            hrefs = request_match('//d:href/text()').map { |el|
              href = el.text
              href.sub!(env['SCRIPT_NAME'], '')

              url_unescape(href)
            }
            resource.report_multiget(hrefs)
          end

        multistatus do |xml|
          report_data.each do |resource|
            xml['d'].response do
              xml['d'].href "#{env['SCRIPT_NAME']}#{resource.path}"
              propstats xml, get_properties(resource, props)
            end
          end
        end

        print_request_response
      end

      def put
        raise Forbidden if resource.collection?

        saved, new_record = resource.put

        if saved
          response['Etag'] = resource.getetag

          if new_record
            status = Created
          else
            status = NoContent
          end
        else
          status = Conflict
        end

        response.status = status
      end

      def delete
        raise NotFound unless resource.exist?
        resource.delete
        response.status = NoContent
      end

    end
  end
end
