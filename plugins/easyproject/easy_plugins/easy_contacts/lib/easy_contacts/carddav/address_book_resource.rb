module EasyContacts
  module Carddav
    ##
    # EasyContactResource
    #
    # Collection of easy contacts
    #
    class AddressBookResource < Resource

      def collection?
        true
      end

      def property_names
        ['resourcetype', 'displayname', 'getctag'].freeze
      end

      def allowed_methods
        ['OPTIONS', 'PROPFIND', 'REPORT'].freeze
      end

      def getctag
        value = last_updated && last_updated.updated_on

        "\"#{value.to_i}\""
      end

      def children
        entities.map do |entity|
          child(entity)
        end
      end

      def resourcetype
        render_xml_element do |xml|
          xml['d'].collection
          xml['card'].addressbook
        end
      end

      def supported_report_set
        render_xml_element do |xml|

          # So far, no client used this method.
          #
          # xml['d'].send('supported-report') do
          #   xml['d'].send('report') do
          #     xml['card'].send('addressbook-query')
          #   end
          # end

          xml['d'].send('supported-report') do
            xml['d'].send('report') do
              xml['card'].send('addressbook-multiget')
            end
          end
        end
      end

      # HTTP REPORT request.
      #
      # addressbook-query
      #
      # So far, no client used this method.
      #
      # def report_query(filters)
      #   EasyContact.visible.map do |entity|
      #     EasyContactResource.new(path + '/' + event.uid + '.vcf', controller, entity)
      #   end
      # end

      # HTTP REPORT request.
      #
      # addressbook-multiget
      #
      def report_multiget(data)
        # Get uids from href element
        data.map! do |href|
          uid = href.split('/').last
          uid.sub!(/\.vcf\Z/, '')
          uid
        end

        # Visible contats (group is there becase webdav have to render 404
        # if resource is not found)
        contacts = grouped_entities_by_uid(data)

        # Contact or not not found
        data.map do |uid|
          contact = contacts[uid].try(:first)

          if contact
            child(contact)
          else
            EasyExtensions::Webdav::StatusResource.new(path + '/' + uid + '.vcf', NotFound)
          end
        end
      end

    end
  end
end
