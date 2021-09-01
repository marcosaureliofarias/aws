class EasyServiceManagerMasterController < ApplicationController

  before_action :check_logged_user

  def index
  end

  def generate
    valid_for = params[:valid_for]
    type = params[:type]
    value = params[:value]

    @service = EasyServiceManager::Services::EasySetting.new
    @service.value = { 'name' => 'internal_user_limit', 'value' => value.to_i }
    @service.valid_for = valid_for
    @token = @service.token
  rescue => e
    flash[:error] = l('easy_service_manager.error_request_is_invalid')
    redirect_to easy_service_manager_master_path
  end

  private

    def check_logged_user
      if User.current.easy_user_type && User.current.easy_user_type.internal?
        # OK
      else
        render_403
      end
    end

end
