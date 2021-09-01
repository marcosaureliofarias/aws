# encoding: UTF-8
class EasyIssuesController < ApplicationController

  menu_item :new_issue, :only => [:new, :create]
  default_search_scope :issues

  include EasyControllersConcerns::DueDateFromVersion

  before_action :find_issue, :only => [:description_edit, :description_update, :load_repeating, :load_history, :favorite, :render_tab, :remove_child]
  before_action :find_optional_project, :only => [:create, :dependent_fields, :move_to_project, :new, :new_for_dialog, :form_fields, :form_fields_v2]
  before_action :find_project_by_last_issue, :only => [:new, :new_for_dialog]
  before_action :build_new_issue_from_params, :only => [:new, :new_for_dialog, :create, :dependent_fields]
  before_action :set_due_date_from_version, :only => [:new, :new_for_dialog, :dependent_fields]

  before_action :authorize, only: [:description_edit, :description_update, :edit_toggle_description, :move_to_project, :render_tab, :remove_child]
  before_action :authorize_global, only: [:find_by_user]

  accept_api_auth :create, :form_fields, :form_fields_v2, :favorite

  helper :journals
  include JournalsHelper
  helper :projects
  include ProjectsHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :issues
  include IssuesHelper
  helper :issue_relations
  include IssueRelationsHelper
  helper :watchers
  include WatchersHelper
  helper :attachments
  include AttachmentsHelper
  helper :sort
  helper :easy_query
  helper :repositories

  def new
    render :template => 'issues/new', :layout => !request.xhr?
  end

  def new_for_dialog
    render :partial => 'easy_issues/new_for_dialog'
  end

  def create
    if @issue.valid?
      ic          = IssuesController.new
      ic.params   = params
      ic.session  = session
      ic.request  = request
      ic.response = response
      ic.instance_eval do
        @url = ActionController::UrlRewriter.new(request, {})
      end
      ic.send :find_project
      ic.send :check_for_default_issue_status
      ic.send :build_new_issue_from_params
      ic.send :create

      redirect_to(response["Location"])
    else
      respond_to do |format|
        format.html render(:template => 'issues/new')
        format.js { render(:template => 'issues/create') }
      end
    end
  end

  def dependent_fields
  end

  def render_preview
    jt = Journal.arel_table

    @issue = Issue.preload(:attachments).find(params[:id])

    # @last_journal = @issue.journals.visible.where("COALESCE(journals.notes, '') <> ''")
    @last_journal = @issue.journals
                        .visible
                        .where(jt[:notes].not_eq('').and(jt[:notes].not_eq(nil)))
                        .order(jt[:id].desc)
                        .limit(1)
                        .first

    respond_to do |format|
      format.html { redirect_to issue_path(@issue) }
      format.js
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def render_tab
    case params[:tab]
    when 'spent_time'
      @query              = EasyTimeEntryQuery.new
      @query.filters      = {}
      @query.column_names = [:user, :spent_on, :activity, :hours, :comments]
      @query.add_additional_statement("#{TimeEntry.table_name}.issue_id = #{@issue.id}")
      render partial: 'issues/tabs/spent_time'

    when 'easy_entity_activity'
      author                    = @issue.assigned_to if @issue.assigned_to.is_a?(User)
      @easy_entity_activities   = @issue.easy_entity_activities.includes(:category, easy_entity_activity_attendees: :entity).sorted
      @new_easy_entity_activity = @issue.easy_entity_activities.build(author: author || User.current).to_decorate
      render partial: 'common/tabs/entity_activities'

    when 'revisions'
      @changesets = @issue.changesets.visible.preload(:repository, user: (Setting.gravatar_enabled? ? :email_address : :easy_avatar))
      if User.current.wants_comments_in_reverse_order?
        @changesets = @changesets.reorder("#{Changeset.table_name}.committed_on DESC, #{Changeset.table_name}.id DESC")
      end
      @changesets = @changesets.to_a
      render partial: 'issues/tabs/revisions'

    else
      render_404
    end
  end

  def description_edit
  end

  def description_update
    if params[:issue]
      journal                = @issue.init_journal(User.current)
      @issue.safe_attributes = params[:issue]

      begin
        @issue.save
      rescue ActiveRecord::StaleObjectError
        @issue.reload
        @issue.safe_attributes = params[:issue]
        @issue.save
      end

      if @issue.errors.count > 0
        flash[:error] = @issue.errors.full_messages.join('<br>')
      else
        flash[:notice] = l(:notice_successful_update)
      end
    end

    redirect_back_or_default(issue_path(@issue))
  end

  def remove_child
    @child = @issue.descendants.find(params[:child_id])

    @child.safe_attributes = { 'parent_issue_id' => nil }

    respond_to do |format|
      if @child.save
        format.html { redirect_to @issue }
        format.js # remove_child.js.erb
      else
        format.html {
          flash[:error] = @child.errors.full_messages.join(', ')
          redirect_to @issue
        }
        format.js { render :js => "alert('#{@child.errors.full_messages.join(', ')}');" }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def toggle_description
    @issue = Issue.find(params[:id])
    respond_to do |format|
      format.js
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def load_repeating
    @issue.easy_is_repeating = true
    respond_to do |format|
      format.js
    end
  end

  def load_history
    @journals = @issue.journals.preload([{ :user => :easy_avatar }, :details]).reorder("#{Journal.table_name}.id ASC").to_a
    @journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
    @journals.reverse! if User.current.wants_comments_in_reverse_order?

    respond_to do |format|
      format.js
    end
  end

  def find_by_user
    scope = User.visible.active.non_system_flag.easy_type_internal.sorted
    scope = scope.like(params[:q]) unless params[:q].blank?

    @user_count = scope.count
    @user_pages = Redmine::Pagination::Paginator.new @user_count, per_page_option, params['page']
    @users      = scope.offset(@user_pages.offset).limit(@user_pages.per_page).to_a

    respond_to do |format|
      format.html do
        if request.xhr?
          render :partial => 'find_by_user_list', :locals => { :users => @users }
        end
      end
      format.js
    end
  end

  def move_to_project
    issues = Issue.where(id: params[:ids])

    issue_ids_for_manual_edit = []
    issues.find_each(:batch_size => 50) do |issue|
      begin
        issue_ids_for_manual_edit << issue.id unless move_issue_to_new_project(issue, @project)
      rescue ActiveRecord::StaleObjectError
        issue.reload
        issue_ids_for_manual_edit << issue.id unless move_issue_to_new_project(issue, @project)
      end
    end

    if issue_ids_for_manual_edit.any?
      flash[:error] = l(
          :error_bulk_update_incompatible_tracker_or_issue_cfs,
          count: issue_ids_for_manual_edit.length
      )
      redirect_to bulk_edit_issues_path(
                      ids:   issue_ids_for_manual_edit,
                      issue: {
                          project_id: @project.id,
                          tracker_id: @incompatible_tracker ? @project.tracker_ids.first : nil
                      }
                  )

    else
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default project_issues_path(@project)
    end

  end

  def favorite
    if User.current.favorite_issues.where(:id => @issue.id).exists?
      User.current.favorite_issues.delete(@issue)
      @favorited = false
    else
      User.current.favorite_issues << @issue
      @favorited = true
    end

    respond_to do |format|
      format.js
      format.html { redirect_to issue_url(@issue) }
      format.api { render_api_ok }
    end
  end

  def form_fields
    if params[:id]
      @issue = Issue.visible.preload(:project).find_by(id: params[:id])
      if @issue
        @project = @issue.project
        return unless update_issue_from_params
      else
        return render_404
      end
    else
      return unless (@issue = build_new_issue_from_params)
    end

    @available_projects = Project.visible.non_templates.allowed_to(:add_issues).sorted

    respond_to do |format|
      format.api
    end
  end

  def form_fields_v2
    if params[:id]
      @issue = Issue.visible.preload(:project).find_by(id: params[:id])
      if @issue
        @project = @issue.project
        return unless update_issue_from_params
      else
        return render_404
      end
    else
      find_project_by_last_issue if params[:find_last_project]
      return unless (@issue = build_new_issue_from_params)
    end

    @available_projects = Project.visible.non_templates.allowed_to(:add_issues).sorted

    respond_to do |format|
      format.api
    end
  end

  private

  def find_issue
    @issue   = Issue.find(params[:id])
    @project = @issue.project if @issue
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    project_id = (params[:issue] && params[:issue][:project_id]) || params[:project_id]
    @project   = Project.find(project_id) unless project_id.blank?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project_by_last_issue
    @project_by_last_issue ||= Issue.non_templates.where(Project.allowed_to_condition(User.current, :add_issues)).where(:author_id => User.current.id).select(:project_id).last.try(:project)
  end

  def move_issue_to_new_project(issue, new_project)
    if !new_project.tracker_ids.include?(issue.tracker_id)
      @incompatible_tracker = true
      return false
    end
    if (assigned = issue.assigned_to)
      assignable = assigned.admin? || assigned.roles.includes(:members).where(:members => { :project_id => new_project }).where(:assignable => true).any?
      return false unless assignable && assigned.allowed_to?(:view_issues, new_project)
    end
    if !issue.safe_attribute?('project_id')
      return false
    end
    new_project_issue_cf_ids = new_project.issue_custom_field_ids.sort
    old_project_issue_cf_ids = issue.project.issue_custom_field_ids.sort
    return false unless new_project_issue_cf_ids == old_project_issue_cf_ids
    issue.init_journal(User.current)
    old_project = issue.project
    issue.project = new_project
    call_hook(:controller_issues_edit_before_save, { params: params, issue: issue, journal: issue.current_journal })
    if issue.save
      call_hook(:controller_issues_edit_after_save, { params: params, issue: issue, journal: issue.current_journal, project: old_project, new_project: new_project })
      true
    else
      false
    end
  end

  def build_new_issue_from_params
    project = @project || @project_by_last_issue
    if params[:id].blank?
      @issue = Issue.new
      @issue.copy_from(params[:copy_from]) if params[:copy_from]
      @issue.project = project
    else
      @issue = project.issues.visible.find_by(:id => params[:id]) if project
      unless @issue
        render_error l(:error_issue_not_found_in_project)
        return false
      end
    end

    return false unless update_issue_from_params

    if !@issue.activity_id && project && project.fixed_activity? && TimeEntryActivity.default
      @issue.activity_id = TimeEntryActivity.default.id
    end

    @issue
  end

  def update_issue_from_params
    @issue.author ||= User.current # safe_attributes cache permissions so author needs to be set before
    @issue.safe_attributes = params[:issue].try(:except, :project_id) || {}
    if @issue.new_record? && params[:issue] && User.current.allowed_to?(:add_issue_watchers, @issue.project)
      @issue.watcher_user_ids  = params[:issue][:watcher_user_ids]
      @issue.watcher_group_ids = params[:issue][:watcher_group_ids]
    end

    if @issue.project
      @issue.tracker ||= @issue.allowed_target_trackers.first
      if @issue.tracker.nil?
        if @issue.project.trackers.any?
          render_error :message => l(:error_no_tracker_allowed_for_new_issue_in_project), :status => 403
        else
          render_error l(:error_no_tracker_in_project)
        end
        return false
      end
      if @issue.status.nil?
        render_error l(:error_no_default_issue_status)
        return false
      end
    end

    @issue.start_date ||= [@issue.project&.start_date, User.current.today].compact.max if Setting.default_issue_start_date_to_creation_date?
    @priorities       = IssuePriority.active
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    true
  end

end
