require 'omniauth-oauth2'
module OmniAuth
  module Strategies
    class SsoEasysoftwareCom < OmniAuth::Strategies::OAuth2

      option :name, :sso_easysoftware_com

      option :client_options, {
          site:          'https://sso.easysoftware.com',
          authorize_url: 'https://sso.easysoftware.com/auth/sso/authorize',
          token_url:     'https://sso.easysoftware.com/auth/sso/token'
      }

      uid do
        raw_info['id']
      end

      info do
        {
            email:      raw_info['info']['email'],
            first_name: raw_info['info']['first_name'],
            last_name:  raw_info['info']['last_name'],
            image:      raw_info['info']['image'],
            name:       raw_info['info']['name'],
            username:   raw_info['info']['username'],
            status:     raw_info['info']['status']
        }
      end

      def raw_info
        @raw_info ||= access_token.get("/auth/sso/user.json?oauth_token=#{access_token.token}").parsed
      end

      def authorize_params
        super.merge(auth_provider: request.params['auth_provider'], auth_url: request.params['auth_url'])
      end

    end
  end
end
