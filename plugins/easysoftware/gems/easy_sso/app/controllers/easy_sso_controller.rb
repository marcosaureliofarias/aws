class EasySsoController < ApplicationController

  before_action :require_admin

  def index
  end

  def save_settings
    save_easy_settings

    flash[:notice] = l(:notice_successful_update)

    redirect_to easy_sso_path
  end

end
