module OmniAuth
  module Strategies
    class EasyOauth2Applications < OmniAuth::Strategies::OAuth2

      option :name, :easy_oauth2_applications

      uid do
        raw_info['uid']
      end

      info do
        raw_info['info']
      end

      extra do
        raw_info['extra']
      end

      def raw_info
        @raw_info ||= access_token.get(options.client_options[:user_info_url]).parsed
      end

    end
  end
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :easy_oauth2_applications, setup: ::EasyOauth2::Setup
end
