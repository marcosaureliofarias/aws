module EasyExtensions
  module Websocket
    class Client

      cattr_accessor(:clients) { {} }
      attr_reader :ws, :user

      def initialize(user, ws)
        @user = user
        @ws   = ws
      end

      def self.create(user, ws = nil)
        self.clients[user.id] = new user, ws
      end

      def delete
        self.class.delete self
      end

      def self.delete(client)
        self.clients.delete client.user.id
      end

      def self.find(user_id)
        self.clients[user_id]
      end

      def send(data)
        ws.send data.to_json
      end

      def touch!
      end

    end
  end
end
