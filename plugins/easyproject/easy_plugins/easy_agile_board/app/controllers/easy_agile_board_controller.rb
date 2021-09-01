class EasyAgileBoardController < ApplicationController

  menu_item :easy_scrum_board

  before_action :find_project
  before_action :authorize, except: :populate

  before_action :redirect_to_new_sprint, only: [:show]
  before_action :find_sprint, except: [:settings, :recalculate, :reorder_project_backlog]
  before_action :find_swimlane_workers, only: [:show]

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

  def show
    return redirect_to easy_agile_board_backlog_path(@project, @easy_sprint) if @easy_sprint.issues.empty?

    if params[:agile_action] == 'backlog'
      return backlog
    elsif params[:agile_action] == 'burndown_chart'
      return burndown_chart
    elsif params[:agile_action] == 'settings'
      return settings
    end

    retrieve_query(EasyAgileBoardQuery, false, dont_use_project: @easy_sprint.cross_project?)
    @query.easy_sprint = @easy_sprint
    @query.add_filter('easy_sprint_id', '=', @easy_sprint.id.to_s)

    respond_to do |format|
      format.html
      format.js
    end
  end

  def backlog
    retrieve_query(EasyAgileBoardQuery, false, dont_use_project: @easy_sprint.cross_project?)
    @query.easy_sprint = @easy_sprint
    @query.outputs = ['scrum_backlog']
  end

  def reorder_project_backlog
    issues = @project.easy_agile_backlog_issues.includes(:easy_agile_backlog_relation)
    reorder(issues, :easy_agile_backlog_relation)
  end

  def reorder_sprint_backlog
    backlog_type = IssueEasySprintRelation::TYPES[IssueEasySprintRelation::TYPE_BACKLOG]

    issues = @easy_sprint.issues.includes(:issue_easy_sprint_relation).where(issue_easy_sprint_relations: { relation_type: backlog_type })
    reorder(issues, :issue_easy_sprint_relation)
  end

  def burndown_chart
    @sprints_chart_data = []
    @project.easy_sprints.order(:start_date).each do |sprint|
      @sprints_chart_data << { name: sprint.name, planned: sprint.capacity, actual: sprint.sum_easy_agile_rating([:done]) }
    end

    @done_tasks_data = []
    @burndown_data = []
    initial_date = @easy_sprint.start_date - 1

    if @easy_sprint.due_date.nil?
      @error = l(:text_easy_agile_board_sprint_due_date_is_empty)
    else
      @burndown_labels = {
        ideal_remaining: l(:label_easy_agile_board_chart_ideal_work_remaining),
        real_remaining: l(:label_easy_agile_board_chart_real_work_remaining),
        issues_remaining: l(:label_easy_agile_board_chart_issues_remaining)
      }

      total_time = @easy_sprint.sum_easy_agile_rating
      total_days = (@easy_sprint.due_date - @easy_sprint.start_date).to_f
      total_issues = @easy_sprint.issues.count

      @burndown_data = [{
                            name: initial_date,
                            ideal_remaining: total_time,
                            real_remaining: (total_time - @easy_sprint.sum_easy_agile_rating([:done], initial_date)).to_i,
                            issues_remaining: (total_issues - @easy_sprint.issue_easy_sprint_relations.until_only_for([:done], initial_date).count)
                        }]

      @easy_sprint.start_date.upto(@easy_sprint.due_date).each_with_index do |chart_date, idx|
        data_point = {}
        data_point[:name] = chart_date
        data_point[:ideal_remaining] = (total_days.zero? ? total_time : ((total_time / total_days) * (total_days - idx))).to_i

        if Date.today >= chart_date
          done_issue_cnt = @easy_sprint.issue_easy_sprint_relations.between_only_for([:done], chart_date, chart_date).count
          @done_tasks_data << { name: data_point[:name], issues_done: done_issue_cnt }

          data_point[:real_remaining] = (total_time - @easy_sprint.sum_easy_agile_rating([:done], chart_date)).to_i
          data_point[:issues_remaining] = (total_issues - @easy_sprint.issue_easy_sprint_relations.until_only_for([:done], chart_date).count)
        end
        @burndown_data << data_point
      end
    end

    respond_to do |format|
      format.html {render template: 'easy_agile_board/burndown_chart'}
    end
  end

  def settings
    unless request.get?
      save_easy_settings(@project)
      flash[:notice] = l(:notice_successful_update)
    end

    retrieve_query(EasyAgileBoardQuery)

    respond_to do |format|
      format.html {render template: 'easy_agile_board/settings'}
    end
  end

  def recalculate
    Issue.where(easy_sprint_id: @project.easy_sprints).find_each(batch_size: 50) do |i|
      if i.easy_agile_backlog_relation && i.closed?
        i.easy_agile_backlog_relation = nil
        i.save
      else
        i.create_or_update_agile_associations
      end
    end
    flash[:notice] = l(:notice_agile_board_statuses_were_recalculated)

    redirect_back_or_default easy_agile_board_settings_path(@project)
  end

  def populate
  end

  private

  def find_sprint
    @easy_sprint = @project.easy_sprints.preload(issues: [:assigned_to, :status, :priority, :project, :tracker]).where(id: params[:sprint_id]).first if params[:sprint_id]
    @easy_sprint ||= @project.current_easy_sprint
    render_404 if @easy_sprint.nil?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_swimlane_workers
    @swimlane_workers = User.
      where(["EXISTS(SELECT #{Issue.table_name}.id FROM #{Issue.table_name} INNER JOIN #{IssueEasySprintRelation.table_name} ON #{IssueEasySprintRelation.table_name}.issue_id = #{Issue.table_name}.id WHERE #{Issue.table_name}.assigned_to_id = #{User.table_name}.id AND #{IssueEasySprintRelation.table_name}.easy_sprint_id = ?)", @easy_sprint.id]).
      sorted
  end

  def redirect_to_new_sprint
    if @project.easy_sprints.empty?
      redirect_to new_project_easy_sprint_path(@project)
      return false
    end
  end

  def redirect_to_current_sprint
    redirect_to easy_agile_board_path(@project, sprint_id: @easy_sprint.id)
  end

  def reorder(issues, relation)
    case params[:by]
    when 'priority'
      # DESC: now most of priorites are in reverse order
      issues = issues.includes(:priority).reorder("#{IssuePriority.table_name}.position DESC")
    else
      issues = nil
    end

    if issues
      EasyAgileBacklogRelation.transaction do
        issues.each_with_index do |issue, i|
          # Position is started from -1 because of jQuery sortable
          issue.send(relation).update_column(:position, i-1)
        end
      end
    end

    redirect_back_or_default easy_agile_board_backlog_path(@project, params[:sprint_id])
  end

end
