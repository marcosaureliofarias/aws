class EasyTimeEntriesController < ApplicationController

  REPORT_COLUMNS_BASE_WIDTH = 40

  menu_item :time_entries

  before_action :find_time_entries, only: [:bulk_edit, :bulk_update, :destroy, :change_issues_for_bulk_edit, :show, :edit, :update]
  before_action :find_optional_project, only: [:new, :create, :index, :report, :load_users]
  before_action :find_entity
  before_action :find_user, only: [:new, :create, :update, :edit, :load_assigned_projects, :load_assigned_issues, :save]

  before_action :authorize, only: [:show, :edit, :update, :bulk_edit, :bulk_update, :destroy]
  before_action :check_easy_lock, only: [:destroy]

  before_action :check_editability, only: [:edit, :update]

  before_action :authorize_global, only: [:new, :create, :index, :report, :user_spent_time, :change_role_activities, :change_projects_for_bulk_edit, :change_issues_for_bulk_edit, :change_issues_for_timelog, :resolve_easy_lock]

  before_action :load_allowed_projects_for_bulk_edit, only: [:bulk_edit, :change_issues_for_bulk_edit, :change_issues_for_timelog]

  before_action :check_for_no_projects, only: [:new]
  before_action :get_top_last_entries, only: [:new, :edit]
  before_action :get_time_entry, only: [:new, :load_assigned_issues, :save, :load_fixed_activities, :create, :update, :edit]
  before_action :set_easy_worker_gauge_meter, only: [:new, :edit]

  accept_rss_auth :index
  accept_api_auth :index, :show, :create, :update, :destroy, :load_assigned_projects, :load_assigned_issues, :load_users

  before_render :time_entries_clear_activities, :load_allowed_issues_for_bulk_edit, :set_selected_visible_issue, only: [:bulk_edit]

  helper :easy_attendances
  helper :easy_query
  include EasyQueryHelper
  helper :custom_fields
  helper :timelog
  include TimelogHelper
  helper :sort
  include SortHelper
  helper :issues

  include EasyUtils::DateUtils

  EasyExtensions::EasyPageHandler.register_for(self, {
      page_name:   'spent-time-overview',
      path:        proc { overview_easy_time_entries_path(t: params[:t]) },
      show_action: :overview,
      edit_action: :overview_layout
  })

  def index
    if params[:from] && params[:to]
      params[:spent_on]   = params[:from] + '|' + params[:to]
      params[:set_filter] = '1'
    end
    retrieve_query(EasyTimeEntryQuery, false, { dont_use_project: @issue.present?, use_session_store: true })
    sort_init(@query.sort_criteria_init)
    sort_update(@query.sortable_columns)

    set_common_variables

    prepare_easy_query_render
    return render_404 if request.xhr? && !@entities

    @query.display_show_sum_row = false
    @query.show_sum_row         = true

    if (f = @query.filters['spent_on']) && f[:values].is_a?(Hash)
      range                   = get_date_range(f[:operator] == 'date_period_1' ? '1' : '2', f[:values][:period], f[:values][:from], f[:values][:to], f[:values][:period_days])
      @from                   = range[:from]
      @to                     = range[:to]
    end

    respond_to do |format|
      format.html { render_easy_query_html }
      format.api { render template: 'timelog/index' }
      format.csv { send_data(export_to_csv(@entities, @query), filename: get_export_filename(:csv, @query)) }
      format.xlsx { render_easy_query_xlsx }
      format.pdf { render_easy_query_pdf }
      format.atom { render_feed(@entities, title: l(:label_spent_time)) }
    end
  end

  def personal_attendance_report
    range = get_date_range('2', 'all', params[:from], params[:to])
    easy_attendance_report = EasyAttendanceReport.new(User.current, range[:from], range[:to])

    respond_to do |format|
      format.html do
        render partial: 'easy_attendances/personal_report', locals: { report: easy_attendance_report }
      end
    end
  end

  def show
    respond_to do |format|
      format.html { render template: 'bulk_time_entries/show' }
      format.api { render template: 'timelog/show' }
    end
  end

  def new
    respond_to do |format|
      format.html {
        render template: 'bulk_time_entries/index'
      }
      format.js {
        if params[:only_custom_fields] == '1'
          render template: 'bulk_time_entries/index_custom_fields'
        elsif params[:modal]
          render action: 'new_modal'
        end
      }
    end
  end

  def edit
  end

  def create
    save
  end

  def update
    save
  end

  def destroy
    @any_with_attendance = false
    @destroyed           = TimeEntry.transaction do
      @time_entries.each do |t|
        if t.easy_attendance.present?
          @any_with_attendance = true
          next
        end
        unless t.destroy && t.destroyed?
          raise ActiveRecord::Rollback
        end
      end
    end

    respond_to do |format|
      format.html {
        if @destroyed
          if @any_with_attendance
            flash[:error] = l(:notice_unable_delete_time_entry_with_attendance)
          else
            flash[:notice] = l(:notice_successful_delete)
          end
        else
          flash[:error] = l(:notice_unable_delete_time_entry)
        end
        redirect_back_or_default project_easy_time_entries_path(@projects.first), :referer => true
      }
      format.js { render template: 'timelog/destroy' }
      format.api {
        if @destroyed
          if @any_with_attendance
            render_api_errors(l(:notice_unable_delete_time_entry_with_attendance))
          else
            render_api_ok
          end
        else
          render_api_errors(l(:notice_unable_delete_time_entry))
        end
      }
    end
  end

  def bulk_edit
    @available_activities = @projects.map(&:activities).reduce(:&)
    @custom_fields        = TimeEntry.first.available_custom_fields.select { |field| field.format.bulk_edit_supported }
    render template: 'timelog/bulk_edit'
  end

  def bulk_update
    attributes = parse_params_for_bulk_update(params[:time_entry])

    unsaved_time_entries = []
    saved_time_entries   = []

    @time_entries.each do |time_entry|
      time_entry.reload
      if attributes[:project_id].present?
        time_entry.project_id = attributes[:project_id]
      end
      if params[:time_entry] && params[:time_entry][:issue_id] == 'no_task'
        time_entry.issue_id = nil
      else
        time_entry.safe_attributes = attributes
      end
      call_hook(:controller_time_entries_bulk_edit_before_save, { params: params, time_entry: time_entry })
      if time_entry.save
        saved_time_entries << time_entry
      else
        unsaved_time_entries << time_entry
      end
    end

    if unsaved_time_entries.empty?
      flash[:notice] = l(:notice_successful_update) unless saved_time_entries.empty?
      redirect_back_or_default project_easy_time_entries_path(@projects.first)
    else
      @saved_time_entries   = @time_entries
      @unsaved_time_entries = unsaved_time_entries

      @time_entries = TimeEntry.visible.where(:id => unsaved_time_entries.map(&:id)).
          preload(:project => :time_entry_activities).
          preload(:user).to_a

      time_entries_clear_activities
      load_allowed_issues_for_bulk_edit
      set_selected_visible_issue
      bulk_edit
    end
  end

  def report
    retrieve_query(EasyTimeEntryQuery, false, { :use_session_store => true })
    @query.display_filter_group_by_on_index = false
    @query.display_filter_settings_on_index = false
    @query.display_outputs_select_on_index  = false
    @query.output                           = 'list'
    @query.group_by                         = nil
    @query.sort_criteria                    = []
    @query.export_formats.delete(:pdf)

    export_options = { url: { controller: :timelog, action: :report } }
    [:xlsx, :csv].each { |format| @query.export_formats[format].merge!(export_options) }

    set_common_variables

    scope = @query.create_entity_scope

    @report = Redmine::Helpers::TimeReport.new(@project, @issue, params[:criteria], params[:columns], scope)

    call_hook(:controller_timelog_report_after_run, params: params, query: @query, report: @report)

    if @report.periods.blank?
      @query.export_formats.delete(:csv)
      @query.export_formats.delete(:xlsx)
      return render_error :status => 422, :message => I18n.t(:error_report_invalid_criteria, :scope => :easy_attendance) if ['csv', 'xlsx'].include?(request.format)
    end

    respond_to do |format|
      format.html { render :layout => !request.xhr? }
      format.csv { send_data(report_to_csv(@report), :type => 'text/csv; header=present', :filename => "#{l(:label_report)}.csv") }
      format.xlsx { send_data(report_to_xlsx(@report, @query, { :caption => :label_report }), :filename => "#{l(:label_report)}.xlsx") }
    end
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

    call_hook(:controller_timelog_edit_before_save, { params: params, time_entry: @time_entry })

    if @time_entry.save
      respond_to do |format|
        format.html do
          if params[:continue]
            flash[:notice] = l(:notice_successful_create)
            redirect_to action: :new, spent_on: @time_entry.spent_on, user_id: @time_entry.user_id,
                        params: new_params, project_id: @project, activity_id: @time_entry.activity_id
          elsif params[:back] && params[:back_url]
            flash[:notice] = l(:notice_successful_create)
            redirect_to url_for(params[:back_url])
          else
            redirect_to action: :show, id: @time_entry.id, params: new_params
          end
        end
        format.js { render action: 'new_modal', locals: { close_modal: true } }
        format.api { render template: 'timelog/show', status: 201 }
      end
    else
      respond_to do |format|
        format.html do
          get_top_last_entries
          set_easy_worker_gauge_meter
          render template: 'bulk_time_entries/index'
        end
        format.js { render action: 'new_modal' }
        format.api { render_validation_errors @time_entry }
      end
    end
  end

  def user_spent_time
    spent_on = []
    spent_on += params[:time_entries].collect { |k, v| v[:spent_on] } if !params[:time_entries].nil?
    spent_on += params[:saved_time_entries].collect { |k, v| v[:spent_on] } if !params[:saved_time_entries].nil?
    spent_on += [params[:spent_on]] if !params[:spent_on].nil?

    render(:partial => 'user_spent_time', :locals => { :spent_on => spent_on })
  end

  def change_role_activities
    @user    = User.find(params[:user_id]) unless params[:user_id].blank?
    @user    ||= User.current
    @project = Project.find(params[:project_id])

    new_project_id = params.delete('new_project_id')
    unless new_project_id.blank?
      begin
        @new_project = Project.find(new_project_id)
      rescue ActiveRecord::RecordNotFound
      end
      @time_entry.project = @new_project
    end

    @entity     = params[:entity_class].constantize.find(params[:entity_id]) unless params[:entity_class].blank? || params[:entity_id].blank?
    @activities = activity_collection(@user, params[:user_role_id])
    respond_to do |format|
      format.js { render template: 'timelog/change_role_activities' }
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def change_projects_for_bulk_edit
    @visible_projects = get_allowed_projects_for_bulk_edit(params[:term], params[:term].blank? ? nil : 15)
    respond_to do |format|
      format.api { render template: 'timelog/change_projects_for_bulk_edit' }
    end
  end

  def change_issues_for_bulk_edit
    respond_to do |format|
      format.api {
        @visible_issues = get_allowed_issues_for_bulk_edit(params[:term], params[:term].blank? ? nil : 15)
        render template: 'timelog/change_issues_for_bulk_edit'
      }
      format.html {
        @visible_issues = get_allowed_issues_for_bulk_edit_scope
      }
    end
  end

  def change_issues_for_timelog
    respond_to do |format|
      format.api {
        @visible_issues = get_allowed_issues_for_bulk_edit(params[:term], params[:term].blank? ? nil : 15)
        render template: 'timelog/change_issues_for_timelog'
      }
      format.html {
        @visible_issues = get_allowed_issues_for_bulk_edit_scope
        render :partial => 'timelog/issues_for_timelog', :locals => {}
      }
    end
  end

  def resolve_easy_lock
    @time_entries = TimeEntry.where(:id => params[:id].presence || params[:ids].presence)
    locked        = params[:locked].presence && params[:locked].to_boolean
    errors        = []
    @time_entries.find_each(:batch_size => 20) do |time_entry|
      time_entry.safe_attributes = { 'easy_locked' => locked }
      if !time_entry.save
        errors << "##{time_entry.id} - #{time_entry.errors.full_messages.join(', ')}"
      end
    end unless locked.nil?

    respond_to do |format|
      format.html do
        flash[:error] = errors.join('<br>'.html_safe) if !errors.empty?
        redirect_back_or_default(:action => 'index')
      end
    end
  end

  def load_users
    respond_to do |format|
      format.json {
        @users = get_users(params[:term])

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

  private

  def check_easy_lock
    if @time_entries.any?(&:easy_locked?)
      render_403(message: l(:error_time_entry_is_locked, :scope => :easy_attendance))
    end
  end

  def get_users(term)
    if User.current.allowed_to?(:add_timeentries_for_other_users_on_project, @project) || User.current.allowed_to_globally?(:add_timeentries_for_other_users)
      User.visible.active.non_system_flag.like(term).sorted.limit(max_limit)
    else
      []
    end
  end

  def get_issues_scope
    if !@time_entry.nil? && !@time_entry.project.nil?
      scope = Issue.visible(@user).joins(:project).where(Project.allowed_to_condition(@user, :log_time, :project => @time_entry.project, :with_subprojects => true)).order(Arel.sql("#{Issue.table_name}.subject"))
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

  def max_limit
    EasySetting.value(:easy_select_limit).to_i
  end

  def check_editability
    unless @time_entry.editable_by?(User.current)
      render_403
      return false
    end
  end

  def find_user
    if !params[:user_id].blank? && User.current.allowed_to_globally?(:add_timeentries_for_other_users) || User.current.allowed_to?(:add_timeentries_for_other_users_on_project, @project)
      @user = User.find_by(id: params[:user_id])
    end
    @user ||= User.current
  end

  def check_for_no_projects
    if count_projects == 0 && request.xhr?
      render action: 'no_projects', format: :js
      return false
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

  def get_time_entry
    begin
      spent_on = Date.parse(params[:spent_on])
    rescue
      spent_on = User.current.today
    end

    time_entry_id = params[:time_entry_id] || params[:id]
    if time_entry_id
      @time_entry = TimeEntry.find_by(id: time_entry_id)
      return render_404 unless @time_entry
      return render_403 unless @time_entry.editable_by?(User.current)
      @time_entry.spent_on = spent_on if params[:spent_on]
      @time_entry.user     = @user if !params[:user_id].blank? && User.current.admin?
    else
      @time_entry = TimeEntry.new(:spent_on => spent_on, :user => @user)
    end

    if @time_entry.new_record? && !params[:project_id]
      @time_entry.project = get_last_project
    elsif (project = find_optional_project) && @user.allowed_to?(:log_time, project)
      @time_entry.project = project
    end

    if params[:user_changed]
      @time_entry.project ||= get_last_project
    end

    if params[:time_entry]
      @time_entry.safe_attributes = params[:time_entry]
    end

    if params[:user_changed] || params[:project_changed]
      @time_entry.issue_id = nil
    elsif params[:issue_id]
      @time_entry.issue = @issue || Issue.find_by(id: params[:issue_id])
      if @time_entry.project && @time_entry.issue
        @time_entry.activity_id = @time_entry.issue.activity_id if EasySetting.value(:project_fixed_activity, @time_entry.project)
        @time_entry.project     = @time_entry.issue.project
      end
    end

    if @time_entry.project.nil?
      @activity_collection = []
    else
      role_id                = @time_entry.project.project_activity_roles.where(role_id: params['user_role_id_time_entry']).present? ? params['user_role_id_time_entry'] : 'xAll'
      @user.selected_role_id = role_id
      # params["user_role_id_time_entry"] ||= @time_entry.user.roles_for_project(@time_entry.project).first.id.to_s
      @activity_collection = activity_collection(@time_entry.user, role_id, @time_entry.project)
    end

    if !@activity_collection.include?(@time_entry.activity)
      @time_entry.activity_id = nil
    elsif @time_entry.activity_id.nil? && @activity_collection.size == 1
      @time_entry.activity_id = @activity_collection.first.id
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

  def get_last_project
    return @last_project unless @last_project.nil?
    time_entry    = TimeEntry.eager_load(:project).
        where(user_id: @user.id).
        where(Project.allowed_to_condition(@user, :log_time)).
        reorder(Arel.sql("#{TimeEntry.table_name}.id DESC")).
        first
    @last_project ||= time_entry.project if time_entry

    @last_project ||= get_projects('', nil, :only_one => true).first
  end

  def get_projects(term = '', limit = nil, options = {})
    scope = get_projects_scope
    if scope
      scope = scope.like(term).limit(limit).reorder(Arel.sql("#{Project.table_name}.lft"))
      options[:only_one] ? [scope.first] : scope.all
    else
      []
    end
  end

  def time_entries_clear_activities
    unless @projects.blank?
      @activities = [] if @projects.detect { |p| p.fixed_activity? }
    end
  end

  def load_allowed_projects_for_bulk_edit
    @visible_projects = get_allowed_projects_for_bulk_edit_scope

    if params[:time_entry] && params[:time_entry][:project_id].present?
      @selected_visible_project = Project.find_by(id: params[:time_entry][:project_id])
    elsif !@time_entry && params[:id]
      find_time_entry
    elsif !@project && params[:project_id]
      find_optional_project
    end

    @selected_visible_project ||= @project
    @selected_visible_project
  end

  def load_allowed_issues_for_bulk_edit
    @visible_issues = get_allowed_issues_for_bulk_edit_scope
  end

  def get_allowed_projects_for_bulk_edit_scope
    if User.current.admin?
      Project.active.non_templates.sorted.has_module(:time_tracking)
    else
      User.current.projects.non_templates.sorted.has_module(:time_tracking).by_permission(:log_time)
    end
  end

  def get_allowed_issues_for_bulk_edit_scope
    if @selected_visible_project
      scope = @selected_visible_project.issues.visible
      scope = scope.joins(:status).where(IssueStatus.table_name => { :is_closed => false }) unless EasyGlobalTimeEntrySetting.value('allow_log_time_to_closed_issue', User.current.roles_for_project(@selected_visible_project))
      scope
    else
      Issue.none
    end
  end

  def get_allowed_projects_for_bulk_edit(term = '', limit = nil)
    get_allowed_projects_for_bulk_edit_scope.like(term).limit(limit)
  end

  def get_allowed_issues_for_bulk_edit(term = '', limit = nil)
    if issues = get_allowed_issues_for_bulk_edit_scope
      issues.like(term).limit(limit)
    end
  end

  def set_selected_visible_issue
    @selected_visible_issue = { name: l(:label_no_change_option), id: '' }
    if params[:time_entry] && params[:time_entry][:issue_id].present? && params[:time_entry][:issue_id] != 'no_task'
      selected_issue          = (@visible_issues || Issue).find_by(id: params[:time_entry][:issue_id])
      @selected_visible_issue = { name: selected_issue.to_s, id: selected_issue.id } if selected_issue
    elsif params[:time_entry].present? && params[:time_entry][:issue_id] == 'no_task'
      @selected_visible_issue = { name: "(#{l(:label_no_task)})", id: 'no_task' }
    elsif @time_entries
      issues                  = @time_entries.collect { |t| t.issue if t.issue }.compact.uniq
      @selected_visible_issue = { name: issues.first.to_s, id: issues.first.id } if issues.size == 1
    end
  end

  def set_common_variables
    @only_me       = params[:only_me].nil? || params[:only_me] == 'false' ? false : true
    @query.only_me = @only_me

    if @issue && params[:with_descendants]
      @query.filters.delete('issue_id')
      @query.add_filter('issue_parent_id', '=', @issue.id)
    end

    @query.add_additional_statement("#{TimeEntry.table_name}.entity_id = #{@entity.id} AND #{TimeEntry.table_name}.entity_type = '#{TimeEntry.connection.quote_string(@entity.class.name)}'") if @entity

    if User.current.allowed_to_globally_view_all_time_entries?
      if @only_me == true
        @query.add_additional_statement("#{TimeEntry.table_name}.user_id = #{User.current.id}")
      end
    else
      @query.add_additional_statement("#{TimeEntry.table_name}.user_id = #{User.current.id}")
    end
  end

  def find_time_entries
    @time_entries = TimeEntry.where(:id => params[:id] || params[:ids]).
        preload(:project => :time_entry_activities).
        preload(:user).to_a
    @time_entry   = @time_entries.first if @time_entries.size == 1

    raise ActiveRecord::RecordNotFound if @time_entries.empty?
    raise Unauthorized unless @time_entries.all? { |t| t.editable_by?(User.current) }
    @projects = @time_entries.collect(&:project).compact.uniq
    @project  = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    if params[:project_changed]
      @project = Project.find(params[:project_id]) if params[:project_id].present?
    elsif params[:issue_id].present? && params[:issue_id] != 'false'
      # find optional issue
      @issue = Issue.find(params[:issue_id])
      @project = @issue.project
    else
      @project = Project.find(params[:project_id]) if params[:project_id].present?
    end

    if @project && !@project.module_enabled?(:time_tracking)
      return render_404
    end

    @project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_entity
    return true if params[:entity_id].blank? || params[:entity_type].blank?

    entity_klass = params[:entity_type].safe_constantize
    @entity      = entity_klass.find(params[:entity_id]) if entity_klass
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
