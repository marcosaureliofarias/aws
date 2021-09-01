# Based on RackDav
# https://github.com/georgi/rack_dav

require 'base64'
require 'digest'
require 'uri'
require 'easy_extensions/webdav/http_status'
require 'easy_extensions/webdav/commons'

module EasyExtensions
  module Webdav
    class Handler
      include EasyExtensions::Webdav::Logger

      def call(env)
        return not_found unless enabled?

        started_at = Time.now

        request  = Rack::Request.new(env)
        response = Rack::Response.new

        begin
          # Controller will create resource and call actions
          # Resource must be initialized after authentification
          # because it may required User.current
          controller = controller_class.new(request, response)
          controller.authenticate
          controller.initialize_resource

          # Check if request method exists
          # 501 is preferable because response does not need Allow header
          method = request.request_method.downcase.to_sym
          if controller.allowed?(method)
            controller.send(method)
          else
            raise WEBrick::HTTPStatus::NotImplemented
          end

        rescue WEBrick::HTTPStatus::Unauthorized => status
          # Basic access authentication
          # controller.send_basic_auth_response

          # Digest access authentication
          controller.send_digest_auth_response

          response.body   = 'Not Authorized'
          response.status = status.code

          response['Content-Type']   = 'text/html'
          response['Content-Length'] = response.body.bytesize.to_s

        rescue WEBrick::HTTPStatus::Status => status
          response.status = status.code
        end

        duration = (Time.now - started_at).round(2)
        log_info("Completed #{response.status.to_i} for #{request.request_method} #{request.fullpath} (in #{duration}s)")

        ActiveSupport::Notifications.instrument('finished.easy_dav',
                                                service_name: service_name,
                                                duration:     duration,
                                                request:      request,
                                                response:     response)

        response.body = [response.body] unless response.body.respond_to?(:each)
        response.finish
      end

      def not_found
        content = 'Not Found'
        [404, { 'Content-Type' => 'text/html', 'Content-Length' => content.size.to_s }, [content]]
      end

      def controller_class
        EasyExtensions::Webdav::Controller
      end

      def service_name
        'webdav'
      end

      def enabled?
        EasySetting.value('easy_webdav_enabled')
      end

    end
  end
end
