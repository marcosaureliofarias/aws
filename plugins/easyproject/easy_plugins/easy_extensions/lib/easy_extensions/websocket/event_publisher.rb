#
# Usage:
#
#
# EasyExtensions::Websocket::EventPublisher.on :connect do
#   puts "User connected #{User.current.id}"
# end
#
# # name of the event (here :message) can be any string and is determined
# # by the "type" key sent by the client
# EasyExtensions::Websocket::EventPublisher.on :message do |data|
#
#   # data is a hash sent by the web browser
#
#   # send data back to the client:
#   client = EasyExtensions::Websocket::Client.find User.current.id
#   client.send data
#
# end
#
# EasyExtensions::Websocket::EventPublisher.on :close do
#   puts "User disconnected #{User.current.id}"
# end
#

module EasyExtensions
  module Websocket
    class EventPublisher

      POLLING_INTERVAL = 5

      def self.on(name, &handler)
        @eventable ||= Hash.new { |hash, key| hash[key] = [] }
        @eventable[name] << handler
        handler
      end

      def self.off(name, handler)
        if @eventable and evts = @eventable[name]
          evts.delete handler
        end
      end

      def self.trigger(name, *args)
        @eventable ||= Hash.new { |hash, key| hash[key] = [] }
        @eventable[name].each { |handler| handler.call(*args) }
      end

      def self.subscriber_id
        @subscriber_id ||= EasyUtils::UUID.generate
      end

      def self.publish_event(data)
        object                          = data.is_a?(Hash) ? data : parse_event_data(data)
        object["current_user_id"]       = User.current.id
        cache_key                       = "EasyExtensions/Websocket/EventPublisher/events"
        published_events                = Rails.cache.fetch(cache_key) || {}
        published_events[subscriber_id] ||= []
        published_events.keys.each do |key, _|
          published_events[key] << object
        end
        Rails.cache.write cache_key, published_events
      end

      def self.start_polling!
        return if @polling_thread.present?
        cache_key = "EasyExtensions/Websocket/EventPublisher/events"
        at_exit do
          published_events = Rails.cache.fetch(cache_key) || {}
          published_events.delete subscriber_id
          Rails.cache.write cache_key, published_events
        end
        @polling_thread ||= Thread.new do
          loop do
            published_events                = Rails.cache.fetch(cache_key) || {}
            published_events[subscriber_id] ||= []
            published_events[subscriber_id].each do |event|
              User.current = User.find(event["current_user_id"])
              trigger event["type"].to_sym, event
            end
            published_events[subscriber_id] = []
            Rails.cache.write cache_key, published_events
            sleep POLLING_INTERVAL
          end
        end
      end

      def self.parse_event_data(data)
        JSON.parse(data) rescue {}
      end

    end
  end
end
