class EasySchedulerController < ApplicationController
  accept_api_auth :index, :personal, :save, :icalendar, :filtered_issues_data, :filtered_easy_crm_cases_data, :user_allocation_data
  menu_item :easy_scheduler

  before_action :require_login
  before_action :check_rest_api_enabled, only: [:index, :personal, :save, :user_allocation_data, :filtered_issues_data, :filtered_easy_crm_cases_data]
  before_action :authorize_global, only: [:index, :personal, :save]
  before_action :retrieve_query, only: [:index, :personal, :filtered_issues_data, :filtered_easy_crm_cases_data, :query_filters]
  before_action :ensure_calendar, only: [:icalendar_link, :icalendar]
  before_action :fetch_principal_ids, only: [:user_allocation_data]

  include_query_helpers

  ICAL_MAX_PAST = 1.month

  def index
    # noinspection RubyStringKeysInHashInspection
    settings = { 'manager' => true }
    render locals: { query: @query, settings: settings }
  end

  def personal
    render action: :index, locals: { query: @query }
  end

  def user_allocation_data
    user_ids = Principal.from('groups_users').where(groups_users: { group_id: @principal_ids }).pluck(:user_id)
    user_ids.concat(@principal_ids)

    @allocations = EasyGanttResource.where(user_id: user_ids, custom: true).where.not(hours: 0)
    @issues = Issue.visible.where(id: @allocations.map(&:issue_id))
    @users = User.preload(:working_time_calendar).visible.where(id: user_ids)

    Issue.load_visible_spent_hours(@issues)

    respond_to do |format|
      format.api
    end
  end

  def filtered_issues_data
    @per_page_option = per_page_option
    @issues = @query.entities(limit: @per_page_option, offset: params[:offset], preload: issue_data_preload_list)
    prepare_issues_data!

    respond_to do |format|
      format.api { render :issues_data }
    end
  end

  def filtered_easy_crm_cases_data
    @per_page_option = per_page_option
    @easy_crm_cases = @query.entities(limit: @per_page_option, offset: params[:offset])
    @currency = @query.easy_currency_code

    user_ids = @easy_crm_cases.map(&:assigned_to_id)
    @users = User.visible.where(id: user_ids)

    respond_to do |format|
      format.api
    end
  end

  # Get data about issues
  #
  # == Params:
  # included_in_query::
  #    Full query params
  #    `query.to_params`
  #    In API on every issue will be new key `included_in_query`
  #    (Hash)
  #
  # included_in_query_id::
  #    Id of sheduler query
  #    In API on every issue will be new key `included_in_query`
  #    (Integer)
  #
  def issues_data
    @issues = Issue.where(id: params[:issue_ids]).preload(issue_data_preload_list)
    prepare_issues_data!

    if params[:included_in_query].is_a?(ActionController::Parameters)
      query_included_in_query = EasySchedulerEasyQuery.new
      query_included_in_query.from_params(params[:included_in_query])

    elsif params[:included_in_query_id]
      query_included_in_query = EasySchedulerEasyQuery.find_by(id: params[:included_in_query_id])
    end

    if query_included_in_query
      @included_in_query_issue_ids = query_included_in_query.create_entity_scope.
                                                             where(issues: { id: @issues }).
                                                             pluck('issues.id')
    end

    respond_to do |format|
      format.api
    end
  end

  def save
    unless params[:issues].is_a?(Array)
      return render_error status: 422
    end

    issue_ids = params[:issues].map { |i| i['id'] }.uniq
    issues = Issue.preload(:status).where(id: issue_ids).index_by(&:id)

    data = {}
    params[:issues].each do |json_issue|
      issue_id = json_issue['id'].to_i
      issue = issues[issue_id]
      next unless issue

      data[issue] = json_issue['allocations']
    end
    saved_resources, unsaved_resources = EasyGanttResource.save_allocation_from_params(data, default_custom: params[:allCustom].to_s.to_boolean)

    if EasyScheduler.easy_gantt_resources?
      issues.each do |_, issue|
        if issue.allocable?
          allocator = EasyGanttResources::IssueAllocator.get(issue)
          allocations = allocator.recalculate!
          saved_resources.each do |issue, resources|
            resources.each do |resource|
              if !allocations.detect { |a| a.date.to_s == resource[:date] && a.hours.to_f == resource[:hours].to_f && a.start.strftime('%H:%M') == resource[:start] && a.custom }
                unsaved_resources[issue] << resource
              end
            end
          end
        else
          issue.easy_gantt_resources.delete_all
          unsaved_resources[issue] << saved_resources[issue]
        end
      end
    end

    errors = unsaved_resources.map do |issue, allocations|
      { issue_id: issue.id, allocations: allocations } unless allocations.blank?
    end
    errors.compact!

    respond_to do |format|
      format.api do
        if errors.blank?
          scheduler_last_save_at = User.current.user_time_in_zone(Time.now)
          render plain: l('easy_scheduler.notice_allocation_last_save_at', save_at: format_time(scheduler_last_save_at)),
                 status: :ok
        else
          render_api_errors errors
        end
      end
    end
  end

  def query_filters
    @block_name = params[:block_name]
    respond_to do |format|
      format.js { render partial: 'easy_scheduler/common/reload_query_filters' }
    end
  end

  def icalendar_link
    @link = easy_calendar_ics_url(key: User.current.api_key, start: '7_days_ago', format: 'ics')

    respond_to do |format|
      format.js
    end
  end

  # @note not used ATM
  def icalendar
    respond_to do |format|
      format.ics do
        icalendar = Icalendar::Calendar.new

        resources = EasyGanttResource.preload(issue: :author).
                                      where(user_id: User.current.id).
                                      where('date > ?', Date.today - ICAL_MAX_PAST)

        resources.each { |resource|
          icalendar.add_event(EasyGanttResourceCalendarEvent.new(resource).to_ical)
        }

        render plain: icalendar.to_ical
      end
    end
  end

  private

  def check_rest_api_enabled
    if Setting.rest_api_enabled != '1'
      render_error message: l('easy_scheduler.errors.no_rest_api')
      false
    end
  end

  def retrieve_query
    if EasyScheduler.easy_extensions?
      query_class = params[:type]&.safe_constantize || EasyScheduler.default_query
    else
      # TODO: query_class = ???
    end
    # render_404 unless EasyScheduler.registered_queries.include?(query_class)

    if params[:query_id]
      @query = query_class.find_by(id: params[:query_id])
    else
      @query = query_class.new(name: '_')
      @query.from_params(params)
    end
  end

  def ensure_calendar
    render_404 unless EasyScheduler.easy_calendar?
  end

  def issue_data_preload_list
    [:fixed_version, :project, :tracker, :priority, :status, project: [:members]]
  end

  def prepare_issues_data!
    Issue.load_visible_spent_hours(@issues)
    Issue.load_custom_allocated_hours(@issues)
    Issue.load_workflow_rules(@issues)

    user_ids = []
    @issues.each do |issue|
      user_ids << issue.assigned_to_id
      user_ids << issue.author_id
    end
    user_ids.uniq!

    @users = User.active.visible.where(id: user_ids)
  end

  def fetch_principal_ids
    @principal_ids = Array.wrap(params[:user_ids].presence).clone
    @principal_ids.reject!(&:blank?)
    selected_additional_options = EasyScheduler::UserPreparation.user_options_with_name.map {|opt| @principal_ids.delete(opt) }.compact
    EasyScheduler::UserPreparation.add_principals_from_options(@principal_ids, selected_additional_options)
  end

end
