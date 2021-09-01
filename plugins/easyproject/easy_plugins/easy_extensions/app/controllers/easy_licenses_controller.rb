class EasyLicensesController < ApplicationController

  before_action :require_admin

  helper :easy_setting
  include EasySettingHelper

  accept_api_auth :index, :update

  def index
    @generated_key = EasySetting.value('license_key')
  end

  def update
    EasyLicenseManager.apply_valid_key(params[:key])

    redirect_to easy_licenses_path
  end

  def validate
    @license_key = EasyLicenseManager.get_valid_easy_license_key
  end

end
