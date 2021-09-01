module EasyExtensions
  module Webdav
    module Logger

      def log_info(*messages)
        log('I', *messages)
      end

      def log_error(*messages)
        log('E', *messages)
      end

      private

      def log(severity, *messages)
        return unless Rails.logger

        prefix = "[#{severity},DAV] [#{Time.now.strftime('%T')}]"

        messages.each_with_index do |message, index|
          Rails.logger.info("#{prefix} #{message}")

          if index.zero?
            prefix = ('-' * prefix.size)
          end
        end
      end

    end
  end
end
