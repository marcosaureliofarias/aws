require 'rys'

module EasyOauth2
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    rys_id 'easy_oauth2'

    initializer 'easy_oauth2.setup' do
      if EasyProjectLoader.can_start?

        EasyExtensions::IdentityProviders.register(-> { EasyOauth2ClientApplication.active.to_a }) do |config, entity|
          config.support_sso   = true
          config.condition     = -> { Rys::Feature.active?('easy_oauth2') }
          config.title         = entity.name
          config.description   = entity.app_url
          config.settings_path = [:edit_easy_oauth2_application_path, entity]
          config.login_path    = entity.oauth2_login_path
          config.show_path     = [:easy_oauth2_application_path, entity]
          config.login_button  = entity.login_button?
        end

        EasyExtensions::IdentityServices.register(-> { EasyOauth2ServerApplication.active.to_a }) do |config, entity|
          config.condition     = -> { Rys::Feature.active?('easy_oauth2') }
          config.title         = entity.name
          config.description   = entity.app_url
          config.settings_path = [:edit_easy_oauth2_application_path, entity]
          config.show_path     = [:easy_oauth2_application_path, entity]
        end

      end
    end
  end
end
