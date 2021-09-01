class EasyGlobalTimeEntrySettingsController < ApplicationController
  include EasySettingHelper

  def new
    role_id = params[:egtes_select].to_i
    @role   = Role.find_by(:id => role_id)
  end

  def create
    @egtes = EasyGlobalTimeEntrySetting.new

    save
  end

  def update
    role_id = params[:easy_global_time_entry_setting][:role_id].blank? ? nil : params[:easy_global_time_entry_setting][:role_id]
    @egtes  = EasyGlobalTimeEntrySetting.find_by(role_id: role_id)

    save
  end

  private

  def save
    respond_to do |format|
      if @egtes
        @egtes.safe_attributes = params[:easy_global_time_entry_setting]
        if @egtes.save
          flash[:notice] = l(:notice_successful_update)
        end
      end
      save_easy_settings
      format.html { redirect_to :back }
    end
  end

end
