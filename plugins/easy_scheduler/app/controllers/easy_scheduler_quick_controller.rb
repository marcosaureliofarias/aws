##
# EasySchedulerQuickController
#
# - Quick scheduler has setting for each user
# - It's replacing calendar from top menu
# - Currently only on EP (delete me if its change)
#
# TODO: Adding a permission?
#
class EasySchedulerQuickController < ApplicationController

  CSS_SELECTOR = '#top-menu .easy-calendar-upcoming .easy-calendar-upcoming__calendar-content'
  CSS_SIDEBAR_SELECTOR = '#easy_servicebar_component_body'

  helper :easy_query

  def show
    respond_to do |format|
      format.js { prepare }
    end
  end

  def setting
    respond_to do |format|
      format.js {
        prepare
        @selected_principal_options = @preparation.selected_principal_options
      }
    end
  end

  def save_setting
    setting = EasySetting.find_or_initialize_by(name: easy_setting_key)
    setting.value = params[:easy_scheduler].present? ? params[:easy_scheduler].to_unsafe_h : {}
    setting.save

    respond_to do |format|
      format.js {
        prepare
        render :show
      }
    end
  end

  private

    def easy_setting_key
      params[:is_toolbar].to_boolean ? "easy_scheduler_toolbar_#{User.current.id}" : "easy_scheduler_quick_#{User.current.id}"
    end

    def prepare
      setting = EasySetting.value(easy_setting_key) || {}
      @preparation = EasyScheduler::Preparation.new(setting)

      @query = @preparation.query
      @scheduler_settings = @preparation.scheduler_settings
      @is_toolbar = params[:is_toolbar].to_boolean
      @scheduler_settings['default_toolbar_zoom'] = 'day' if @is_toolbar.present?
    end

end
