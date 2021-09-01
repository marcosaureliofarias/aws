module EasyExtensions
  module Websocket
    class RackApp

      def call(env)
        req = ActionDispatch::Request.new env

        unless User.current = User.where(id: req.session["user_id"]).first
          return unauthorized
        end

        if Faye::WebSocket.websocket?(req.env)
          websocket_request req
        else
          normal_http_request req
        end
      end

      def websocket_request(req)
        ws           = Faye::WebSocket.new req.env, ping: 5
        current_user = User.current
        client       = Client.create User.current, ws
        EventPublisher.publish_event "type" => :connect

        ws.on :message do |event|
          User.current = current_user
          EventPublisher.publish_event event.data
        end
        ws.on :close do |event|
          User.current = current_user
          EventPublisher.publish_event "type" => :close
          Client.delete client
        end

        ws.rack_response # return async Rack::Response
      end

      def normal_http_request(req)
        if req.get?
          if client = Client.find(User.current.id)
            client.touch!
            ok_with_data client.data_to_send.to_json
          else
            client = FallbackClient.create User.current
            EventPublisher.publish_event "type" => :connect
            ok_with_data client.data_to_send.to_json
          end
        elsif req.post?
          if client = Client.find(User.current.id)
            client.touch!
          else
            FallbackClient.create User.current
          end
          EventPublisher.publish_event req.params['data']
          ok_with_data
        else
          ok
        end
      end

      def ok_with_data(data = '{}')
        [200, { 'Content-Type' => 'text/plain' }, [data]]
      end

      def ok
        [200, { 'Content-Type' => 'text/plain' }, ['Hello, this is a websocket resource.']]
      end

      def unauthorized
        [401, { 'Content-Type' => 'text/plain' }, ['Unauthorized, login required.']]
      end

    end
  end
end
