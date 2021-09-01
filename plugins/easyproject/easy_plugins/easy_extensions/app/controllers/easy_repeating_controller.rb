class EasyRepeatingController < ApplicationController
  before_action :require_login
  before_action :find_entity

  def show_repeating_options
    @entity.easy_repeat_settings                  = params.to_unsafe_hash['easy_repeat_settings'] unless params['easy_repeat_settings'].blank?
    @entity.easy_repeat_settings['period']        ||= 'daily'
    @entity.easy_repeat_settings['daily_option']  ||= 'each'
    @entity.easy_repeat_settings['yearly_option'] ||= 'date'
    @entity.easy_repeat_settings['endtype']       ||= 'endless'
    @entity.easy_is_repeating                     = true
    @first_dow                                    ||= EasyExtensions::Calendars::Calendar.first_wday

    @object_name = params[:object_name]
    @settings    = @entity.easy_repeat_settings
    respond_to do |format|
      format.js
      format.html
    end
  end

  def disable_easy_repeating
    @entity.update_attributes({ :easy_is_repeating => false, :easy_repeat_settings => {}, easy_next_start: nil, easy_repeat_simple_repeat_end_at: nil })

    respond_to do |format|
      format.js
    end
  end

  private

  def find_entity
    @entity = params[:entity_type].constantize.find_or_initialize_by(id: params[:entity_id])
  rescue StandardError
    render_404
  end
end
