class EasyServiceManagerController < ApplicationController

  before_action :require_admin
  before_action :load_service, only: [:verify, :apply]

  def index
  end

  def verify
  end

  def apply
    begin
      @service.execute
      flash[:notice] = l(:notice_successful_update)
    rescue => e
      flash[:error] = l(:notice_failed_to_update)
    end

    redirect_to easy_service_manager_path
  end

  private

    def load_service
      @service = EasyServiceManager::Services::EasySetting.new
      @service.token = params[:token]
    rescue => e
      flash[:error] = l('easy_service_manager.error_token_is_invalid')
      redirect_to easy_service_manager_path
      false
    end

end
