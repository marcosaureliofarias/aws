require_relative 'concerns/easy_agile_controller_methods'

class EasyKanbanIssuesController < ApplicationController

  include Concerns::EasyAgileControllerMethods
  self.assignment_class_name = 'EasyKanbanIssue'

  helper :custom_fields
  helper :issues

  before_action :find_issue, only: [:update]
  before_action :find_project_by_project_id
  before_action :authorize
  before_action :check_if_can_change_issue, only: [:update]

  def update
    if params[:easy_kanban_issue].key?(:phase) && EasyKanbanIssue.not_assigned_phase?(params[:easy_kanban_issue][:phase])
      @issue.easy_kanban_issue(@project) && @issue.easy_kanban_issue(@project).destroy
      head :ok
    else
      begin
        EasyKanbanIssue.transaction do
          @issue.init_journal(User.current)
          @issue.skip_workflow = true unless EasySetting.value('easy_agile_use_workflow_on_kanban', @project)
          @issue.skip_update_associated_agile_relations = true
          position = params[:easy_kanban_issue].delete(:position)
          phase = params[:easy_kanban_issue].delete(:phase)
          phase_status = EasySetting.value('kanban_statuses', @project)['progress'][phase]['status_id'].to_i if phase.to_i > 0
          easy_kanban_issues = @issue.easy_kanban_issues
          easy_kanban_issues << EasyKanbanIssue.new(issue: @issue, project: @project) unless @issue.easy_kanban_issue(@project)
          easy_kanban_issues.each do |easy_kanban_issue|
            easy_kanban_issue.phase = phase_status ? easy_kanban_issue.phase_for_status_from_settings(phase_status) : phase
            easy_kanban_issue.position = position || count_position(easy_kanban_issue, params[:easy_kanban_issue])
            easy_kanban_issue.save!
          end
          @issue.safe_attributes = params[:easy_kanban_issue]
          @issue.skip_update_associated_agile_relations = false if @issue.will_save_change_to_status_id?
          @issue.save!
        end
      rescue ActiveRecord::RecordInvalid
        render json: { errors: @issue.errors.full_messages + @issue.easy_kanban_issues.map{|eki| eki.errors.full_messages }.flatten.compact }, status: :unprocessable_entity
        return
      end

      @positions = EasyKanbanIssue.where(project_id: @project.id, phase: @issue.kanban_phase(@project)).order(:position).pluck(:issue_id, :phase, :position)
      @use_workflow = EasySetting.value('easy_agile_use_workflow_on_kanban', @project)
      @possible_phases = EasyKanbanIssue.kanban_phase_for_statuses(@issue, @project, @use_workflow)

      respond_to do |format|
        format.api { render template: 'easy_kanban/data' }
      end
    end
  end

  private

  def check_if_can_change_issue
    deny_access if @issue && !@issue.attributes_editable?(User.current)
  end      

end
