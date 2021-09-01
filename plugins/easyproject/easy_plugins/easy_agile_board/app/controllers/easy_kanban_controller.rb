class EasyKanbanController < ApplicationController

  menu_item :easy_kanban_board

  helper :projects
  helper :easy_query
  include EasyQueryHelper
  helper :easy_setting
  include EasySettingHelper
  helper :sort
  include SortHelper

  before_action :find_project
  before_action :authorize
  before_action :check_setting, except: [:settings]

  def show
    retrieve_query(EasyAgileBoardQuery)
  end

  def backlog
    retrieve_query(EasyAgileBoardQuery)
    @query.outputs = ['agile_backlog']

    respond_to do |format|
      format.html
    end
  end

  def settings
    unless request.get?
      save_easy_settings(@project)
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default project_easy_kanban_settings_path(@project)
    end
    retrieve_query(EasyAgileBoardQuery)
  end

  def recalculate
    Issue.with_kanban_issues_of_project(@project).find_each(batch_size: 50) do |issue|
      if issue.easy_agile_backlog_relation && issue.closed?
        issue.easy_agile_backlog_relation = nil
        issue.save
      else
        issue.create_or_update_agile_associations
      end
    end

    flash[:notice] = l(:notice_agile_board_statuses_were_recalculated)

    redirect_back_or_default project_easy_kanban_settings_path(@project)
  end

  def changed_issues
    changed_from = params[:timestamp].try(:to_time) rescue nil
    if changed_from
      @issues = @project.issues.joins(:easy_kanban_issues).where('updated_on > ?', changed_from)

      respond_to do |format|
        format.api { render template: 'issues/index'}
      end
    end
  end

  private

  def check_setting
    if EasySetting.value('kanban_statuses', @project).nil?
      flash[:warning] = l(:warning_missing_setting)
      redirect_to(action: :settings, back_url: project_easy_kanban_backlog_path(@project))
      false
    end
  end
end
