class EasyAttendanceSettingsController < ApplicationController

  layout 'admin'
  before_action :require_admin
  before_action :find_plugin

  def index
    @easy_user_working_time_calendars = EasyUserWorkingTimeCalendar.templates
    @settings                         = Setting.send "plugin_#{@plugin.id}"
  end

  def plugin_settings
    Setting.send "plugin_#{@plugin.id}=", params[:settings]
    flash[:notice] = l(:notice_successful_update)
    redirect_to easy_attendance_settings_path(@plugin)
  end

  private

  def find_plugin
    @plugin = Redmine::Plugin.find(:easy_attendances)
  rescue Redmine::PluginNotFound
    render_404
  end

end
