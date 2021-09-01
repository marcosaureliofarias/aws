require 'rys'

module EasySso
  module SamlServer
    class Engine < ::Rails::Engine
      include Rys::EngineExtensions

      rys_id 'easy_sso_saml_server'

      initializer 'easy_sso_saml_server.setup' do
        config.after_initialize do
          begin
            if EasyProjectLoader.can_start? && ActiveRecord::Base.connection.table_exists?('easy_settings')
              EasyExtensions::IdentityServices.register(:saml_server) do |config|
                config.condition     = -> { Rys::Feature.active?('easy_sso.saml_server') }
                config.title         = -> { 'SAML IDP' } # EasySso::SamlClient::Settings.name }
                config.description   = -> { 'SAML IDP' } # I18n.t(:description, scope: [:rys_features, :easy_sso_saml_client]) }
                config.settings_path = :easy_sso_saml_server_settings_path
                # config.show_path     = [:easy_oauth2_application_path, entity]
              end
            end
          rescue ActiveRecord::NoDatabaseError
          end
        end
      end
    end
  end
end
