require_relative 'concerns/easy_agile_controller_methods'

class EasySprintsController < ApplicationController

  menu_item :easy_scrum_board

  before_action :find_easy_sprint, only: [:show, :edit, :update, :destroy, :assign_issue, :open, :close, :close_dialog, :reorder]
  before_action :find_agile_project, except: [:global_index, :overview, :layout, :new]
  before_action :find_optional_project, only: [:new]
  before_action :authorize, except: [:global_index, :overview, :layout, :new]
  before_action :authorize_global, only: [:global_index, :new]
  before_action :find_issue_by_issue_id, only: [:assign_issue]
  before_action :check_if_can_change_issue, only: [:assign_issue]

  include Concerns::EasyAgileControllerMethods
  self.assignment_class_name = 'IssueEasySprintRelation'

  helper :sort
  include SortHelper
  helper :easy_query
  include EasyQueryHelper
  helper :issues
  helper :projects
  helper :easy_agile_board
  helper :easy_sprints
  helper :easy_setting
  include EasySettingHelper
  helper :easy_icons

  EasyExtensions::EasyPageHandler.register_for(self, {
    page_name: 'easy-sprint-overview',
    path: proc { overview_easy_sprints_path(t: params[:t]) },
    show_action: :overview,
    edit_action: :layout
  })

  def index
    redirect_to easy_agile_board_path(@project)
  end

  def global_index
    index_for_easy_query EasySprintQuery, [['start_date', 'desc']]
  end

  def autocomplete
    @easy_sprints = @project.easy_sprints.like(params[:term]).sorted_by_date

    respond_to do |format|
      format.api
    end
  end

  def show
    redirect_to easy_agile_board_path(@project, sprint_id: @easy_sprint)
  end

  def new
    @easy_sprint = EasySprint.new
    @easy_sprint.project = @project
    @easy_sprint.safe_attributes = params[:easy_sprint]
    if @project
      respond_to do |format|
        format.html
        format.js
      end
    else
      respond_to do |format|
        format.js { render partial: 'easy_sprints/new_without_project' }
        format.html { render_404 }
      end
    end
  end

  def create
    @easy_sprint = EasySprint.new
    @easy_sprint.project = @project
    @easy_sprint.safe_attributes = params[:easy_sprint]

    if @easy_sprint.save
      setting = EasySetting.find_or_initialize_by(name: "easy_sprint_burndown_#{@easy_sprint.id}")
      setting.value = params[:easy_sprint][:summable_column_for_burndown]
      setting.save

      if ['selected', 'all'].include?(params[:move_task]) && params[:sprint_relations].is_a?(Array)
        issue_ids = []
        params[:sprint_relations].each do |sprint_relation|
          scope = IssueEasySprintRelation.where(relation_type: sprint_relation['relation_type'])

          if params[:move_task] == 'selected' && EasySprint.where(id: params[:selected_sprint_id]).exists?
            scope = scope.where(easy_sprint_id: params[:selected_sprint_id])
          elsif params[:move_task] == 'all'
            scope = scope.where(easy_sprint_id: @project.easy_sprints.pluck(:id))
          else
            scope = scope.none
          end
          issue_ids.concat(scope.pluck(:issue_id))
          scope.update_all(easy_sprint_id: @easy_sprint.id)
        end
        Issue.where(id: issue_ids).update_all(easy_sprint_id: @easy_sprint.id)
      end

      respond_to do |format|
        format.html { redirect_after_create }
        format.js
      end
    else
      respond_to do |format|
        format.html { render action: 'new' }
        format.js { render action: 'new' }
      end
    end
  end

  def edit
    @easy_sprint.safe_attributes = params[:easy_sprint]

    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    @easy_sprint.safe_attributes = params[:easy_sprint]

    if @easy_sprint.save
      setting = EasySetting.find_or_initialize_by(name: "easy_sprint_burndown_#{@easy_sprint.id}")
      setting.value = params[:easy_sprint][:summable_column_for_burndown]
      setting.save

      respond_to do |format|
        format.html { redirect_back_or_default easy_agile_board_path(@project, sprint_id: @easy_sprint) }
        format.js
        format.json do
          if @easy_sprint.capacity > 0
            capacity_percentage = @easy_sprint.sum_easy_agile_rating / @easy_sprint.capacity.to_f * 100
          else
            capacity_percentage = 0
          end
          sprint = @easy_sprint.as_json.merge(capacity_percentage: format_number(capacity_percentage, "%d%%" % capacity_percentage, no_html: true))
          render json: {easy_sprint: sprint}
        end
      end
    else
      respond_to do |format|
        format.html { render action: 'edit' }
        format.js { render action: 'edit' }
        format.json { render json: {error: @easy_sprint.errors.full_messages.join(". ")} }
      end
    end
  end

  def destroy
    @easy_sprint.destroy
    redirect_back_or_default easy_agile_board_path(@project)
  end

  def assign_issue
    @errors = []
    project = @easy_sprint.project
    IssueEasySprintRelation.transaction do
      @issue.init_journal(User.current)
      @issue.skip_workflow = true unless EasySetting.value('easy_agile_use_workflow_on_sprint', @project)
      @issue.skip_update_associated_agile_relations = true
      phase = params[:issue_easy_sprint_relation][:phase]
      if phase == 'project_backlog'
        if @issue.closed?
          @issue.errors.add(:base, l(:error_assign_closed_issues_to_project_backlog))
        else
          # Be careful: similar logic is in {Issue#easy_project_backlog=}
          IssueEasySprintRelation.where(issue_id: @issue.id).destroy_all
          @issue.update(easy_sprint: nil) if @issue.easy_sprint.present?
          if assignment = @issue.easy_agile_backlog_relation
            assignment.project = project
          else
            assignment = project.easy_agile_backlog_relations.build(issue: @issue)
          end
          assignment.new_position = params[:issue_easy_sprint_relation].delete(:position) || count_position(assignment, params[:issue_easy_sprint_relation])
          assignment.save
          @errors.concat(assignment.errors.full_messages)
        end
      elsif phase == '0'
        EasyAgileBacklogRelation.where(issue_id: @issue.id).destroy_all
        IssueEasySprintRelation.where(issue_id: @issue.id).destroy_all
        @issue.update(easy_sprint: nil) if @issue.easy_sprint
      else
        assignment = @issue.issue_easy_sprint_relation
        assignment ||= @issue.build_issue_easy_sprint_relation
        EasyAgileBacklogRelation.where(issue_id: @issue.id).destroy_all
        assignment.easy_sprint = @easy_sprint
        @issue.easy_sprint = @easy_sprint
        assignment.new_position = params[:issue_easy_sprint_relation].delete(:position) || count_position(assignment, params[:issue_easy_sprint_relation]) || :bottom
        assignment.relation_type = phase
        @saved = assignment.save
        @errors.concat(assignment.errors.full_messages)
        raise ActiveRecord::Rollback, 'Record not saved' unless @saved
      end
      if parent_issue_id = params[:issue_easy_sprint_relation].delete(:parent_id)
        params[:issue_easy_sprint_relation][:parent_issue_id] = parent_issue_id
      end
      @issue.safe_attributes = params[:issue_easy_sprint_relation]
      @issue.skip_update_associated_agile_relations = false if @issue.will_save_change_to_status_id?
      @saved = @issue.save
      raise ActiveRecord::Rollback, 'Record not saved' unless @saved
    end
    @errors.concat(@issue.errors.full_messages)

    if @errors.any?
      respond_to do |format|
        format.js
        format.json { render json: {error: @errors}, status: :unprocessable_entity }
      end
    else
      respond_to do |format|
        format.js
        format.api {
          @use_workflow = EasySetting.value('easy_agile_use_workflow_on_sprint', project)
          @possible_phases = IssueEasySprintRelation.kanban_phase_for_statuses(@issue, project, @use_workflow)
          @positions = IssueEasySprintRelation.where(easy_sprint_id: @easy_sprint.id).pluck(:issue_id, :relation_type, :position) + EasyAgileBacklogRelation.where(project_id: project).pluck(:issue_id, :position).each { |x| x.insert(1, 'project_backlog') }
          render template: 'easy_kanban/data' }
      end
    end
  end

  def unassign_issue
    issue = Issue.find(params[:issue_id])
    issue.init_journal(User.current)

    EasyAgileBacklogRelation.where(issue_id: issue.id).destroy_all
    issue.update(easy_sprint: nil)
    render_api_ok
  rescue ActiveRecord::RecordNotFound
    flash_message([l(:error_issue_not_found)])
  end

  def open
    if !@easy_sprint.update_attribute(:closed, false)
      @errors = @easy_sprint.errors.full_messages
    end

    respond_to do |format|
      format.js
    end
  end

  def close_dialog
    @allowed_issue_statuses = @easy_sprint.available_close_issue_statuses

    respond_to do |format|
      format.js
    end
  end

  def close
    easy_sprint_params = params[:easy_sprint]

    if easy_sprint_params
      close_all_issues = easy_sprint_params[:close_all_issues].to_s.to_boolean
      close_issue_status = IssueStatus.find_by(id: easy_sprint_params[:close_issue_status])
    end

    if @easy_sprint.update_attribute(:closed, true)
      if close_all_issues && close_issue_status
        @easy_sprint.close_all_issues(close_issue_status)
      end
    else
      @errors = @easy_sprint.errors.full_messages
    end

    respond_to do |format|
      format.html { redirect_back_or_default easy_agile_board_backlog_path(@project, @easy_sprint) }
      format.js
    end
  end

  private

  def find_easy_sprint
    @easy_sprint = EasySprint.preload(issues: [:assigned_to, :status, :priority, :project, :tracker]).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_agile_project
    @project = Project.find(params[:project_id]) if params[:project_id]
    @project ||= @easy_sprint.project if @easy_sprint

    render_404 if @project.nil?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_issue_by_issue_id
    # Issue.visible.find(...) can not be used to redirect user to the login form
    # if the issue actually exists but requires authentication
    @issue = Issue.find(params[:issue_id])
    raise Unauthorized unless @issue.visible?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def flash_message(messages)
    api_request? ? render_api_errors(messages) : render(js: "showFlashMessage('error', '#{messages.join('<br>').html_safe}');", status: :unprocessable_entity)
  end

  def redirect_after_create
    redirect_back_or_default easy_agile_board_backlog_path(@project, @easy_sprint)
  end

  def check_if_can_change_issue
    deny_access if @issue && !@issue.attributes_editable?(User.current)
  end

end
