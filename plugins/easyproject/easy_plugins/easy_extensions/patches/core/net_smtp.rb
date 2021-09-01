# As of the moment of this patch Net::SMTP does not support SNI yet
# There is only a fix for IMAP https://bugs.ruby-lang.org/issues/15594
# but it is unclear if there will be such a fix for SMTP and when it will come
# and if it will be backported to all the Ruby versions we officially support

module EasyPatch
  module Net
    module SMTP

      def ssl_socket(socket, context)
        ssl_socket = super
        ssl_socket.hostname = @address if ssl_socket.respond_to?(:hostname=)
        ssl_socket
      end
      private :ssl_socket

    end
  end
end

class Net::SMTP
  prepend EasyPatch::Net::SMTP
end
