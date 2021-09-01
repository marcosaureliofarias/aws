require 'rys'

module EasySso
  module SamlClient
    class Engine < ::Rails::Engine
      include Rys::EngineExtensions

      rys_id 'easy_sso_saml_client'

      config.after_initialize do
        begin
          if EasyProjectLoader.can_start? && ActiveRecord::Base.connection.table_exists?('easy_settings')
            EasyExtensions::IdentityProviders.register(:saml_client) do |config|
              config.support_sso   = true
              config.condition     = -> { Rys::Feature.active?('easy_sso.saml_client') }
              config.title         = -> { EasySso::SamlClient::Settings.name }
              config.description   = -> { I18n.t(:description, scope: [:rys_features, :easy_sso_saml_client]) }
              config.settings_path = :easy_sso_saml_client_settings_path
              config.login_path    = '/auth/saml'
              config.login_button  = -> { EasySso::SamlClient::Settings.login_button? }
              config.checked       = -> { EasySso::SamlClient::Settings.idp_checked? }
            end
          end
        rescue ActiveRecord::NoDatabaseError
        end
      end
    end
  end
end
