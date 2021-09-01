class EasySsoSamlServerSettingsController < ApplicationController

  def index
    @saml_settings = SamlServerSettings.new
  end

  def save_settings
    save_easy_settings

    settings            = SamlServerSettings.new
    settings.attributes = params[:saml_server_settings].to_unsafe_h
    settings.save

    flash[:notice] = l(:notice_successful_update)

    redirect_back_or_default easy_sso_saml_server_settings_path
  end

end
