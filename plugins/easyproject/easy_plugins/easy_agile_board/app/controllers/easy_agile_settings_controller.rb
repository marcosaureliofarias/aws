class EasyAgileSettingsController < ApplicationController

  helper :easy_query
  include EasyQueryHelper
  helper :easy_setting
  include EasySettingHelper
  helper :sort
  include SortHelper

  before_action :require_admin, only: [:index, :save_global_settings]

  layout 'admin'
  menu_item :easy_agile_default_settings

  def index
    @tab = params[:tab]
    retrieve_query(EasyAgileBoardQuery)
  end

  def save_global_settings
    save_easy_settings(@project)
    flash[:notice] = l(:notice_successful_update)
    redirect_back_or_default global_easy_agile_settings_path(tab: params[:tab])
  end
end

