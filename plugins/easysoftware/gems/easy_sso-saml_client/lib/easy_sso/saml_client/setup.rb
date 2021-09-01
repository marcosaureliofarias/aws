module EasySso
  module SamlClient
    class Setup

      def self.call(env)
        new(env).setup
      end

      def initialize(env)
        @env = env
      end

      def setup
        @env['omniauth.strategy'].options.merge!(options)
      end

      def options
        EasySso::SamlClient.hash_settings
      end

    end
  end
end
