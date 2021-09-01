module EasyExtensions
  module Websocket
    class FallbackClient < Client

      def self.data_to_send(user_id)
        cache_key    = "EasyExtensions/Websocket/FallbackClient/#{user_id}"
        cached_value = Rails.cache.fetch cache_key
        Rails.cache.delete cache_key
        cached_value || []
      end

      def data_to_send
        self.class.data_to_send(self.user.id)
      end

      def self.update_data_to_send(user_id, new_data)
        data = self.data_to_send(user_id)
        data << new_data
        cache_key = "EasyExtensions/Websocket/FallbackClient/#{user_id}"
        Rails.cache.write cache_key, data
      end

      def initialize(ws, user)
        super
        setup_inactivity_timeout
      end

      def setup_inactivity_timeout
        touch!
        Thread.new do
          loop do
            sleep 60
            if @last_active_at < 60.seconds.ago
              User.current = @user
              EventPublisher.publish_event "type" => :close
              self.delete
              break
            end
          end
        end
      end

      def touch!
        @last_active_at = Time.now
      end

      def send(data)
        self.class.update_data_to_send(self.user.id, data)
      end

    end
  end
end
