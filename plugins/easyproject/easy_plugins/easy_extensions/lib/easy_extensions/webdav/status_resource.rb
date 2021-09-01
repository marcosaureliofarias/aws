module EasyExtensions
  module Webdav
    ##
    # EasyExtensions::Webdav::StatusResource
    #
    # This resource have not any properties. Is used
    # for resources returning only HTTP status.
    # For example 404 Not Found.
    #
    class StatusResource

      attr_reader :path, :status

      def initialize(path, status)
        @path   = path
        @status = status
      end

      def code
        @status.code
      end

      def reason_phrase
        @status.reason_phrase
      end

      def collection?
        path.end_with?('/')
      end

    end
  end
end
