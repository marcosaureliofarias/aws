# https://github.com/ruby/ruby/pull/1030
require 'webrick/httpstatus'

module WEBrick
  module HTTPStatus

    class Status < StandardError
      def self.to_i
        code
      end
    end

  end
end
