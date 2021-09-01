class EasySchedulerEntityModalsController < ApplicationController
  before_action :collect_combine_modal_tabs, only: [:combine_modal], if: -> { params[:event].present? }
  before_action :find_or_build_entity_activity, only: [:easy_entity_activity_modal]

  include_query_helpers

  def combine_modal
    modal = {
      content: render_to_string(partial: 'entity_tabs_modal'),
      title: render_to_string(partial: 'entity_tabs_head')
    }
    respond_to do |format|
      format.js { render json: modal.to_json }
    end
  end

  def easy_entity_activity_modal
    @decorated_obj = EasyEntityActivityDecorator.new(@entity_activity)
    respond_to do |format|
      format.html { render partial: 'easy_entity_activity_modal' }
    end
  end

  def reload_contacts
    @selected = []
    case params[:entity_type]
    when 'EasyCrmCase'
      find_easy_crm_case
      @selected += @easy_crm_case.easy_contacts.visible.map{|contact| {value: contact.name, id: contact.id} }
    when 'EasyContact'
      find_easy_contact
      @selected += [{value: @easy_contact.name, id: @easy_contact.id}]
    end

    respond_to do |format|
      format.js
    end
  end

  def reload_activity_entity
    respond_to do |format|
      format.js
    end
  end

  private

  def find_easy_crm_case
    @easy_crm_case = EasyCrmCase.visible.where(id: params[:id]).first
    return render_404 unless @easy_crm_case.present?
  end

  def find_easy_contact
    @easy_contact = EasyContact.visible.where(id: params[:id]).first
    return render_404 unless @easy_contact.present?
  end

  def find_or_build_entity_activity
    if params[:id].present?
      @entity_activity = EasyEntityActivity.where(id: params[:id]).first
      return render_404 unless @entity_activity.present?
    else
      @entity_activity = EasyEntityActivity.new(params.permit(:start_time, :end_time, :all_day))
    end
  end

  def collect_combine_modal_tabs
    event = params[:event]
    @tabs = []
    event_start_date = Time.parse(event[:start_date]) rescue nil
    event_end_date = Time.parse(event[:end_date]) rescue nil
    event_duration = (event_end_date - event_start_date) / 1.hour if event_end_date && event_start_date

    if EasyScheduler.easy_calendar?
      url = new_easy_meeting_path(easy_meeting: {start_time: event[:start_date], end_time: event[:end_date], all_day: event[:all_day]})
      @tabs << { name: 'meeting', label: l('easy_scheduler.label_meeting'), ajax_url: url }
    end

    url = issues_new_for_dialog_path(issue: { start_date: event[:start_date],
                                              estimated_hours: event_duration,
                                              assigned_to_id: params[:user_id] })
    @tabs << { name: 'issue', label: l(:label_issue, scope: :easy_scheduler), ajax_url: url }

    if EasyScheduler.easy_attendances?
      url = new_easy_attendance_path(arrival_at: event[:start_date], departure: event[:end_date], format: :html)
      @tabs << { name: 'easy_attendance', label: l('easy_scheduler.label_attendance'), ajax_url: url }
    end
    if EasyScheduler.easy_entity_activities?
      url = easy_scheduler_easy_entity_activity_modal_path(start_time: event[:start_date], end_time: event[:end_date], all_day: event[:all_day])
      @tabs << { name: 'easy_entity_activity', label: l('easy_scheduler.label_sales_activity'), ajax_url: url }
    end
  end

end
