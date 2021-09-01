module EasyExtensions
  module Webdav
    ##
    # EasyExtensions::Webdav::Controller
    #
    # == Status:
    # 403 (Forbidden)::
    #   the request should not be repeated because it will always fail
    #
    # 409 (Conflict)::
    #   it is expected that the user might be able to resolve the conflict and resubmit the request
    #
    # 412 (Precondition Failed)::
    #   conditions (if header) is not met
    #
    class Controller
      include WEBrick::HTTPStatus
      include EasyExtensions::Webdav::Logger

      # NEVER use X namespace
      NAMESPACES = {
          'xmlns:d'    => 'DAV:',
          'xmlns:easy' => 'https://www.easysoftware.com/ns'
      }

      PROP_NAMESPACES = {

      }.tap { |h| h.default = 'd' }

      attr_reader :request, :response, :resource

      def initialize(request, response)
        # Go back is forbiden
        if request.path_info.include?('../')
          raise Forbidden
        end

        @request  = request
        @response = response
      end

      def initialize_resource
        # Resource for specific URL
        res = resource_class
        if res.blank?
          raise NotFound
        end

        @resource = res.new(path_info, self)
      end

      def resource_class
        case path_info
        when '/', '/attachment'
          CollectionResource

          # OK:  /attachment/81
          # OK:  /attachment/81.doc
          # OK:  /attachment/81.text.doc
          # BAD: /attachment/81/
          # BAD: /attachment/81.doc/
        when /\A\/attachment\/\d+[^\/]*\Z/
          AttachmentResource
        end
      end

      def set_localization
        @@languages_lookup ||= I18n.available_locales.map { |l| [l.to_s.downcase, l] }.to_h

        lang        = User.current.language.presence || Setting.default_language
        I18n.locale = @@languages_lookup[lang]
      end


      # Authentication and authorization
      # =======================================================================

      def send_basic_auth_response
        response['WWW-Authenticate'] = "Basic realm='Locked content'"
      end

      def send_digest_auth_response
        time_stamp = Time.now.to_i
        h_once     = Digest::MD5.hexdigest("#{time_stamp}:#{SecureRandom.hex(32)}")

        nonce = Base64.strict_encode64("#{time_stamp}#{h_once}")

        response['WWW-Authenticate'] = %{Digest realm="#{User::DIGEST_AUTHENTICATION_REALM}", nonce="#{nonce}", algorithm="MD5", qop="auth"}
      end

      # == Possible problems:
      # - Windows could send DOMAIN in username
      #
      def authenticate
        auth_header = request.env['HTTP_AUTHORIZATION']
        scheme      = auth_header && auth_header.split(' ', 2).first.downcase

        # Redmine session authentication (on browser)
        if user_id = request.session['user_id']
          log_info('Authentication: session')

          User.current = User.find_by_id(user_id)

          # Digest authentication
        elsif scheme == 'digest'
          log_info('Authentication: digest')

          auth   = Rack::Auth::Digest::Request.new(request.env)
          params = auth.params

          username = params['username']
          response = params['response']
          cnonce   = params['cnonce']
          nonce    = params['nonce']
          uri      = params['uri']
          qop      = params['qop']
          nc       = params['nc']

          user = User.find_by_login(username)
          if user.nil?
            log_error('Digest authentication: provided user name has no match in the DB')
            raise Unauthorized
          end

          ha1 = user.easy_digest_token
          ha2 = Digest::MD5.hexdigest("#{request.env['REQUEST_METHOD']}:#{uri}")

          if qop
            required_response = Digest::MD5.hexdigest("#{ha1}:#{nonce}:#{nc}:#{cnonce}:#{qop}:#{ha2}")
          else
            required_response = Digest::MD5.hexdigest("#{ha1}:#{nonce}:#{ha2}")
          end

          if required_response == response
            User.current = user
          else
            log_error('Digest authentication: digest response is incorrect')
          end

          # Basic authentication
        elsif scheme == 'basic'
          log_info('Authentication: basic')

          auth = Rack::Auth::Basic::Request.new(request.env)

          if auth.basic? && auth.credentials
            username = auth.credentials[0]
            password = auth.credentials[1]

            User.current = User.try_to_login(username, password)
          end
        end

        log_info("Current user: #{User.current} (id=#{User.current.id})",
                 "User-Agent: #{request.user_agent}")

        if User.current.anonymous?
          raise Unauthorized
        end
      end


      # HTTP Requests
      # =======================================================================

      def allowed?(method)
        respond_to?(method) && resource.allowed?(method)
      end

      def options
        header_dav   = ['1']
        header_allow = []

        if resource.lockable?
          header_dav << '2'
          header_allow.concat(['LOCK', 'UNLOCK'].freeze)
        end

        header_allow.concat(resource.allowed_methods)
        header_dav.concat(resource.header_dav)

        if resource.controlled_access?
          header_dav << 'access-control'
        end

        response['Dav']           = header_dav.join(',')
        response['Allow']         = header_allow.join(',')
        response['Ms-Author-Via'] = 'DAV'
      end

      def head
        raise NotFound if !resource.exist?
        raise NotImplemented if resource.collection?

        response['Etag']           = resource.getetag
        response['Content-Type']   = resource.getcontenttype
        response['Content-Length'] = resource.getcontentlength.to_s
        response['Last-Modified']  = resource.getlastmodified
      end

      def get
        head
        resource.get
      end

      # == Statuses:
      #
      # Created (201)::
      #   The resource was created successfully
      #
      # No Content (204)::
      #   With PUT, the 204 response allows the server to send back an updated etag
      #   and other entity information about the resource that has been affected by
      #   the PUT operation. This allows the client to do the next PUT using the
      #   If-Match precondition to ensure that edits are not lost.
      #
      def put
        raise Forbidden if resource.collection?

        resource.put
        response.status = Created
      end

      # == Variables:
      # names::
      #   Specific or all names (empty). Cannot be set now because of depth
      #   depth header => every resource can have a different properties.
      #
      # only_names::
      #   Client is asking only for property names not values.
      #
      def propfind
        raise NotFound unless resource.exist?
        only_name  = false
        namespaces = {}

        # Retrieve all properties
        if request_match('/d:propfind/d:allprop').any? || request_body.root.nil?
          names = []

          # Retrieve all property names
        elsif request_match('/d:propfind/d:propname').any?
          names     = []
          only_name = true

          # Retrieving named properties
        else
          props      = request_match('/d:propfind/d:prop/*')
          names      = props.map(&:name)
          namespaces = props.map { |prop|
            [prop.name, prop.namespace.try(:href)]
          }
          namespaces = Hash[namespaces]
          raise BadRequest if names.blank?
        end

        render_multistatus(find_resources, names, only_name, namespaces)

        print_request_response
      end

      def lock
        raise MethodNotAllowed unless resource.lockable?
        raise NotFound unless resource.exist?

        timeout = request_timeout
        if timeout.nil? || timeout.zero?
          timeout = 60
        end

        if request_body.content.empty?
          refresh_lock(timeout)
        else
          create_lock(timeout)
        end
      end

      def unlock
        raise MethodNotAllowed unless resource.lockable?

        token = request_locktoken('LOCK_TOKEN')
        raise BadRequest if token.nil?

        response.status = resource.unlock(token)
      end


      # Locking
      # =======================================================================

      def request_timeout
        timeout = request.env['HTTP_TIMEOUT']
        return if timeout.nil? || timeout.empty?

        timeout = timeout.match /Second\-(\d+)/
        timeout && timeout[1].to_i
      end

      def request_locktoken(header)
        token = request.env["HTTP_#{header}"]
        return if token.nil? || token.empty?

        token = token.match /^\(?<?(.+?)>?\)?$/
        token && token[1]
      end

      def create_lock(timeout)
        options           = {}
        options[:timeout] = timeout
        options[:scope]   = request_match('local-name(/d:lockinfo/d:lockscope/d:*[1])')
        options[:type]    = request_match('local-name(/d:lockinfo/d:locktype/d:*[1])')
        options[:owner]   = request_match('/d:lockinfo/d:owner').text
        options[:path]    = request.path

        lock_instance = resource.lock(options)
        render_lockdiscovery(lock_instance)

        response['Lock-Token'] = lock_instance.token
      end

      def refresh_lock(timeout)
        token = request_locktoken('IF')
        raise BadRequest if token.nil?

        options           = {}
        options[:timeout] = timeout
        options[:token]   = token
        options[:path]    = request.path

        lock_instance = resource.lock(options)
        render_lockdiscovery(lock_instance)
      end

      def render_lockdiscovery(lock_instance)
        render_xml do |xml|
          xml['d'].prop(self.class::NAMESPACES) do
            xml['d'].lockdiscovery do

              resource.render_lock(xml, lock_instance)

            end
          end
        end
      end


      # Others
      # =======================================================================

      def url_unescape(url)
        Addressable::URI.unescape(url).force_encoding(Encoding::UTF_8)
      end

      def path_info
        @path_info ||= url_unescape(request.path_info)
      end

      def request_method
        @request_method ||= request.request_method.downcase.to_sym
      end

      def env
        @request.env
      end

      def depth
        case env['HTTP_DEPTH']
        when '0' then
          0
        when '1' then
          1
        else
          100
        end
      end

      def find_resources
        case depth
        when 0
          [resource]
        when 1
          [resource] + resource.children
        else
          [resource] + resource.descendants
        end
      end

      def request_body
        return @request_body if @request_body

        body = request.body.read

        if body.empty?
          @request_body = Nokogiri::XML::Document.new
        else
          @request_body = Nokogiri::XML(body, &:strict)
        end

      rescue Nokogiri::XML::SyntaxError, RuntimeError
        raise BadRequest
      end

      def request_match(pattern)
        match(request_body, pattern)
      end

      def match(data, pattern)
        data.xpath(pattern, self.class::NAMESPACES)
      end

      def render_xml
        content = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          yield xml
        end.to_xml

        response.body              = [content]
        response['Content-Type']   = 'text/xml; charset=utf-8'
        response['Content-Length'] = content.bytesize.to_s
      end

      def multistatus
        render_xml do |xml|
          xml['d'].multistatus(self.class::NAMESPACES) do
            yield xml
          end
        end

        response.status = MultiStatus
      end

      def rexml_convert(xml, element)
        ns = element.namespace && element.namespace.prefix

        new_xml = ns.nil? ? xml : xml[ns]

        if element.elements.empty?
          if element.text
            new_xml.send("#{element.name}_", element.text, element.attributes)
          else
            new_xml.send("#{element.name}_", element.attributes)
          end
        else
          new_xml.send(element.name.to_sym, element.attributes) do
            element.elements.each do |child|
              rexml_convert(xml, child)
            end
          end
        end
      end

      def render_multistatus(resources, names, only_name = false, namespaces = {})
        multistatus do |xml|
          resources.each do |resource|
            xml['d'].response do
              xml['d'].href "#{env['SCRIPT_NAME']}#{resource.path}#{'/' if resource.collection?}"
              propstats xml, get_properties(resource, names, only_name), namespaces
            end
          end
        end
      end

      def render_error(message)
        render_xml do |xml|
          xml['d'].error(self.class::NAMESPACES) do
            xml['easy'].message(message)
          end
        end
      end

      # There is a difference between resource is not found
      # or property key is not found (or defined)
      def propstats(xml, stats, namespaces = {})
        if stats.is_a?(StatusResource)
          xml['d'].status "#{request.env['HTTP_VERSION']} #{stats.code} #{stats.reason_phrase}"
          return
        end

        return if stats.empty?

        stats.each do |status, props|
          xml['d'].propstat do
            xml['d'].prop do
              props.each do |name, value|
                # DO NOT USE IT
                # Some programs do not like missing attributes
                # next if value.nil?

                ns = self.class::PROP_NAMESPACES[name]

                case value
                when Nokogiri::XML::Node
                  xml[ns].send(name) do
                    rexml_convert(xml, value)
                  end

                when Nokogiri::XML::NodeSet
                  xml[ns].send(name) do
                    value.each do |node|
                      rexml_convert(xml, node)
                    end
                  end

                  # Special case
                  # - empty value (should not happend)
                  # - unknown props (maybe with unknown namespace)
                when NilClass
                  if href = namespaces[name]
                    # Find if href is already used
                    xmlns = xml.doc.namespaces.detect { |_, v| v == href }
                    if xmlns
                      ns = xmlns.first.sub('xmlns:', '')
                      xml[ns].send(name)
                    else
                      # Take namespace from request body if it can be
                      xml['X'].send(name, 'xmlns:X' => href)
                    end

                    # Fallback to default
                  else
                    xml[ns].send(name)
                  end

                when EasyExtensions::Webdav::CData
                  xml[ns].send(name) { xml.cdata(value) }

                else
                  xml[ns].send(name, value)

                end
              end
            end

            xml['d'].status "#{request.env['HTTP_VERSION']} #{status.code} #{status.reason_phrase}"
          end
        end
      end

      # No value parameter is used for propname request
      def get_properties(resource, names, only_name = false)
        # Resource is HTTP status (e.g. Not Found)
        return resource if resource.is_a?(StatusResource)

        # Get properties from resources
        stats = Hash.new { |hash, key| hash[key] = [] }

        # All properties
        if names.blank?
          names = resource.property_names
        end

        names.each do |name|
          if only_name
            value = nil
          else
            value = resource.get_property(name)
          end

          if value.is_a?(Status)
            stats[value.class] << name
          else
            stats[OK] << [name, value]
          end
        end
        stats
      end

      def print_request_response(also_response = true)
        return unless Rails.env.development?

        puts request_body.to_s

        if also_response
          puts
          puts '---'
          puts
          puts response.body.is_a?(Array) ? response.body.join("\n") : response.body
        end
      end

    end
  end
end
