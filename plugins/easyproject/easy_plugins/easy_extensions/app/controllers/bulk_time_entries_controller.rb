# encoding: utf-8
class BulkTimeEntriesController < ApplicationController

  before_action :authorize_global
  before_action :try_find_optional_project
  before_action :find_user
  before_action :check_for_no_projects, :only => [:index]
  before_action :get_top_last_entries, :only => [:index]
  before_action :get_time_entry, :only => [:index, :load_assigned_issues, :save, :load_fixed_activities]
  before_action :set_easy_worker_gauge_meter, :only => [:index]

  helper :custom_fields
  helper :issues
  include IssuesHelper
  helper :timelog
  include TimelogHelper
  helper :easy_query
  include EasyQueryHelper
  helper :easy_attendances
  include EasyAttendancesHelper

  accept_api_auth :load_users, :load_assigned_projects, :load_assigned_issues, :show

  def index
    if params[:modal] && request.xhr?
      render 'index_modal'
    elsif params[:only_custom_fields] == '1' && request.xhr?
      render 'index_custom_fields'
    end
  end

  def load_users
    respond_to do |format|
      format.json {
        @users = get_users
        @users = @users.select { |u| /#{Regexp.escape(params[:term])}/i.match?(u.name) } unless params[:term].blank?
        render :json => @users.collect { |u| { :value => u.name, :id => u.id } }
      }
    end
  end

  def load_assigned_projects
    respond_to do |format|
      format.json {
        @projects  = get_projects(params[:term], max_limit)
        @self_only = false
        render :template => 'easy_auto_completes/projects_with_id', :formats => [:json]
      }
    end
  end

  def load_assigned_issues
    respond_to do |format|
      format.json {
        @issues = get_issues(params[:term], max_limit)
        render :json => @issues.collect { |i| { :value => i.to_s, :id => i.id } }
      }
    end
  end

  def load_fixed_activities
    render :partial => 'timelog/user_time_entry', :locals => { :required        => true,
                                                               :tag_name_prefix => 'time_entry',
                                                               :time_entry      => @time_entry,
                                                               :activities      => @activity_collection,
                                                               :project         => @time_entry.project, :issue => @time_entry.issue }
  end

  def save
    new_params                    = {}
    new_params[:page_module_uuid] = params[:page_module_uuid] if params[:page_module_uuid]
    new_params[:spent_on]         = params[:spent_on] if params[:spent_on]
    new_params[:back_url]         = params[:back_url] if params[:back_url]
    new_params[:modal]            = params[:modal] if params[:modal]
    new_params[:issue_id]         = params[:issue_id] if params[:issue_id] && params[:modal]

    if @time_entry.issue && @time_entry.project != @time_entry.issue.project
      @time_entry.project = @time_entry.issue.project
    end

    if @time_entry.project && @time_entry.project.fixed_activity? && @time_entry.activity_id.blank?
      @time_entry.activity_id = @time_entry.issue.activity_id if @time_entry.issue
    end

    call_hook(:controller_bulk_time_entries_save_before_save, { time_entry: @time_entry })

    if @time_entry.save
      respond_to do |format|
        format.html do
          if params[:continue]
            flash[:notice] = l(:notice_successful_create)
            redirect_to action: :index, spent_on: @time_entry.spent_on, user_id: @time_entry.user_id,
                        params: new_params, project_id: @project
          elsif params[:back] && params[:back_url]
            flash[:notice] = l(:notice_successful_create)
            redirect_to url_for(params[:back_url])
          else
            redirect_to action: :show, time_entry_id: @time_entry.id, params: new_params
          end
        end
        format.js { render action: :index_modal, locals: { close_modal: true } }
        format.api { render template: 'timelog/show', status: 201 }
      end
    else
      respond_to do |format|
        format.html do
          get_top_last_entries
          set_easy_worker_gauge_meter
          render action: :index
        end
        format.js { render action: :index_modal }
        format.api { render_validation_errors @time_entry }
      end
    end
  end

  def show
    @time_entry = TimeEntry.find(params[:time_entry_id])
    respond_to do |format|
      format.html
      format.js
      format.api { render template: 'timelog/show' }
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private

  def max_limit
    EasySetting.value(:easy_select_limit).to_i
  end

  def find_user
    if !params[:user_id].blank? && User.current.allowed_to_globally?(:add_timeentries_for_other_users) || User.current.allowed_to?(:add_timeentries_for_other_users_on_project, @project)
      @user = User.find_by(id: params[:user_id])
    end
    @user ||= User.current
  end

  def get_last_project
    return @last_project unless @last_project.nil?
    time_entry    = TimeEntry.eager_load(:project).
        where(user_id: @user.id).
        where(Project.allowed_to_condition(@user, :log_time)).
        reorder("#{TimeEntry.table_name}.id DESC").
        first
    @last_project ||= time_entry.project if time_entry

    @last_project ||= get_projects('', nil, :only_one => true).first
  end

  def get_last_issue
    if params[:issue_id]
      last_issue = Issue.find(params[:issue_id])
    elsif params[:action] != 'save' && @time_entry && @time_entry.issue
      last_issue = @time_entry.issue
    else
      last_issue = @issues ? @issues.first : nil
    end
    last_issue
  end

  def get_time_entry
    begin
      spent_on = Date.parse(params[:spent_on])
    rescue
      spent_on = User.current.today
    end

    if params[:time_entry_id]
      @time_entry = TimeEntry.find(params[:time_entry_id])
      return render_403 unless @time_entry.editable_by?(User.current)
      @time_entry.spent_on = spent_on if params[:spent_on]
      @time_entry.user     = @user if !params[:user_id].blank? && User.current.admin?
    else
      @time_entry = TimeEntry.new(:spent_on => spent_on, :user => @user)
    end

    if @time_entry.new_record? && (!params[:project_id] || params[:user_changed])
      @time_entry.project = get_last_project
    elsif (project = try_find_optional_project) && @user.allowed_to?(:log_time, project)
      @time_entry.project = project
    end

    if params[:time_entry]
      @time_entry.safe_attributes = params[:time_entry]
    end

    if (params[:user_changed] || params[:project_changed])
      @time_entry.issue_id = nil
    elsif params[:issue_id].present?
      @time_entry.issue = Issue.find_by(id: params[:issue_id])
      if @time_entry.project && @time_entry.issue
        @time_entry.activity_id = @time_entry.issue.activity_id if EasySetting.value(:project_fixed_activity, @time_entry.project)
        @time_entry.project     = @time_entry.issue.project
      end
    end

    if @time_entry.project.nil?
      @activity_collection = []
    else
      # params["user_role_id_time_entry"] ||= @time_entry.user.roles_for_project(@time_entry.project).first.id.to_s
      @activity_collection = activity_collection(@time_entry.user, params['user_role_id_time_entry'], @time_entry.project)
    end

    if !@activity_collection.include?(@time_entry.activity)
      @time_entry.activity_id = nil
    elsif @time_entry.activity_id.nil? && @activity_collection.size == 1
      @time_entry.activity_id = @activity_collection.first.id
    end
    call_hook(:controller_bulk_time_entries_get_time_entry, { params: params, time_entry: @time_entry })
  end

  def get_users
    if User.current.allowed_to?(:add_timeentries_for_other_users_on_project, @project) || User.current.allowed_to_globally?(:add_timeentries_for_other_users)
      User.visible.active.non_system_flag.sorted
    else
      []
    end
  end

  def count_users
    get_users.count
  end

  def get_projects_scope
    if @user.blank?
      nil
    elsif @user.admin?
      s = Project.non_templates.sorted.active_and_planned.has_module(:time_tracking)
    else
      s = @user.projects.active_and_planned.non_templates.sorted.where(Project.allowed_to_condition(@user, :log_time))
    end
    if s && User.current.allowed_to?(:add_timeentries_for_other_users_on_project, @project)
      s = s.where(Project.allowed_to_condition(User.current, :add_timeentries_for_other_users_on_project))
    end
    s
  end

  def get_projects(term = '', limit = nil, options = {})
    scope = get_projects_scope
    if scope
      scope = scope.like(term).limit(limit).reorder("#{Project.table_name}.lft")
      options[:only_one] ? [scope.first] : scope.all
    else
      []
    end
  end

  def count_projects
    scope = get_projects_scope
    if scope
      @project_count ||= scope.count
    else
      @project_count ||= 0
    end
  end

  def get_issues_scope
    if !@time_entry.nil? && !@time_entry.project.nil?
      scope = Issue.visible(@user).joins(:project).where(Project.allowed_to_condition(@user, :log_time, :project => @time_entry.project, :with_subprojects => true)).order("#{Issue.table_name}.subject")
      scope = scope.joins(:status).where(IssueStatus.table_name => { :is_closed => false }) unless EasyGlobalTimeEntrySetting.value('allow_log_time_to_closed_issue', User.current.roles_for_project(@time_entry.project))
      scope = scope.where(:project_id => @time_entry.project) if !Setting.display_subprojects_issues? || params[:without_subprojects]
      scope
    else
      nil
    end
  end

  def get_issues(term = '', limit = nil, options = {})
    scope = get_issues_scope
    if scope
      scope = scope.like(term)
      options[:only_one] ? [scope.first] : scope.limit(limit).to_a
    else
      []
    end
  end

  def count_issues
    scope = get_issues_scope
    if scope
      @issues_count ||= scope.count
    else
      @issues_count ||= 0
    end
  end

  def find_project
    @selected_project = try_find_optional_project
    if @selected_project.nil?
      time_entry        = TimeEntry.where(["#{TimeEntry.table_name}.user_id = ?", @user.id]).where(Project.allowed_to_condition(@user, :log_time)).eager_load(:project).order("#{TimeEntry.table_name}.id DESC").first
      @selected_project = time_entry.project if time_entry
    end
    @selected_project ||= Project.visible.has_module(:time_tracking).first
  end

  def try_find_optional_project
    @project ||= (Project.find(params[:project_id]) unless params[:project_id].blank?)
  rescue ActiveRecord::RecordNotFound
  end

  def check_for_no_projects
    if count_projects == 0 && request.xhr?
      render :action => 'no_projects', :format => :js
      return false
    end
  end

  def get_top_last_entries
    if !params[:user_changed].blank? || !request.xhr?
      @top_last_entries = Project.visible(@user).active_and_planned.has_module(:time_tracking).
          select("#{Project.table_name}.id, #{Project.table_name}.name").
          where(["#{TimeEntry.table_name}.user_id = ?", @user.id]).
          joins(:time_entries).
          group("#{Project.table_name}.id, #{Project.table_name}.name").
          reorder(Arel.sql("MAX(#{TimeEntry.table_name}.created_on) DESC")).
          limit(10).all
    else
      @top_last_entries = []
    end
  end

  def set_easy_worker_gauge_meter
    if @time_entry && @time_entry.user && @time_entry.spent_on
      @gauge_meter_spent_time = TimeEntry.non_templates.visible_with_archived.where(:user_id => @time_entry.user_id).
          where(["#{TimeEntry.table_name}.spent_on BETWEEN ? AND ?", @time_entry.spent_on, @time_entry.spent_on]).sum(:hours)
      @gauge_meter_max_value  = @time_entry.user.current_working_time_calendar.nil? ? 0 : @time_entry.user.current_working_time_calendar.sum_working_hours(@time_entry.spent_on, @time_entry.spent_on)
      @gauge_meter_label      = "#{@time_entry.user.name} (#{format_date(@time_entry.spent_on)})"
    else
      @gauge_meter_spent_time = 0
      @gauge_meter_max_value  = 0
      @gauge_meter_label      = @user.name
    end
  end

end
