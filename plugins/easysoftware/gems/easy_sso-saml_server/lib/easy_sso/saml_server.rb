require 'rys'

require 'easy_sso'
require 'easy_sso/saml_server/version'
require 'easy_sso/saml_server/engine'

require 'saml_idp'

module EasySso
  module SamlServer

    module Settings
      class << self

        def default_url_options
          if Rails.env.production?
            { protocol: Setting.protocol, host: Setting.host_name }
          else
            { protocol: "http", host: "localhost", port: "3000" }
          end
        end

        def host_name
          if Rails.env.production?
            "#{Setting.protocol}://#{Setting.host_name}"
          else
            "http://localhost:3000"
          end
        end

        def setting(name)
          EasySetting.value("easy_sso_saml_server_#{name}").presence
        end

        def issuer
          host_name
        end

        def metadata_url
          Rails.application.routes.url_helpers.easy_sso_saml_server_metadata_url(default_url_options)
        end

        def login_url
          Rails.application.routes.url_helpers.signin_url(default_url_options)
        end

        def active?
          setting('active') == '1'
        end

        def x509_certificate
          setting('x509_certificate')
        end

        def secret_key
          setting('secret_key')
        end

        def password
          setting('password')
        end

        def algorithm
          (setting('algorithm') && setting('algorithm').to_sym) || :sha256
        end

      end
    end

  end
end
