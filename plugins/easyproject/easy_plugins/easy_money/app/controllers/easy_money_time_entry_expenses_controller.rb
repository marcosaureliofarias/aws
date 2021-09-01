class EasyMoneyTimeEntryExpensesController < ApplicationController

  menu_item :easy_money

  before_action :find_easy_money_project, :only => [:index, :update_project_time_entry_expenses, :update_project_and_subprojects_time_entry_expenses]
  before_action :authorize, :only => [:index, :update_project_time_entry_expenses, :update_project_and_subprojects_time_entry_expenses]
  before_action :require_admin, :only => [:update_all_projects_time_entry_expenses]
  before_action :load_current_easy_currency_code, only: [:index]

  helper :custom_fields
  include CustomFieldsHelper
  helper :easy_money
  include EasyMoneyHelper
  helper :attachments
  include AttachmentsHelper
  helper :sort
  include SortHelper

  def index
    sort_init 'project', 'asc'
    sort_update 'project' => "#{Project.table_name}.name", 'subject' => "#{Issue.table_name}.subject"

    case params[:format]
    when 'csv', 'pdf'
      @limit = Setting.issues_export_limit.to_i
    when 'atom'
      @limit = Setting.feeds_limit.to_i
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end

    issue_scope = get_issue_scope
    @project_time_entries = get_project_time_entry_scope.to_a

    @issues_count = issue_scope.count
    @issues_pages = Redmine::Pagination::Paginator.new @issues_count, @limit, params['page']
    @offset ||= @issues_pages.offset
    @issues = issue_scope.order(sort_clause).offset(@offset).limit(@limit)

    respond_to do |format|
      format.html do
        if request.xhr? && !params[:with_wbs_money]
          render partial: 'issue_time_entry', locals: { easy_currency_code: @current_easy_currency_code,
                                                        url_params: { project_id: @project } }
        else
          render layout: !request.xhr?
        end
      end
      format.csv { send_data(easy_money_time_entries_to_csv(@project_time_entries, @issues, @project.easy_money_settings)) }
    end
  end

  def update_project_time_entry_expenses
    create_recompute_rake_task([@project.id])

    if request.xhr?
      head :ok
    else
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default({:controller => 'easy_money_settings', :action => 'project_settings', :project_id => @project, :tab => 'EasyMoneyRatePriority'})
    end
  end

  def update_project_and_subprojects_time_entry_expenses
    create_recompute_rake_task(@project.self_and_descendants.active_and_planned.has_module(:easy_money).pluck(:id))

    if request.xhr?
      head :ok
    else
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default({:controller => 'easy_money_settings', :action => 'project_settings', :project_id => @project, :tab => 'EasyMoneyRatePriority'})
    end
  end

  def update_all_projects_time_entry_expenses
    create_recompute_rake_task

    if request.xhr?
      head :ok
    else
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default({:controller => 'easy_money_settings', :action => 'index', :tab => 'EasyMoneyRatePriority'})
    end
  end

  private

  def create_recompute_rake_task(project_ids = nil)
    @recompute_rake_task = OneTimeEasyRakeTask.create_one_time_task('update_projects_time_entry_expenses', {:project_ids => project_ids}).easy_rake_task
  end

  def add_scope_conditions(scope)
    scope = scope.includes(:easy_money_time_entry_expenses).joins(:project)
    scope = if @project.easy_money_settings.include_childs?
      scope.where(:project_id => @project.self_and_descendants.has_module(:easy_money)) #also comute archived
    else
      scope.where(:project_id => @project.id)
    end
  end

  def get_project_time_entry_scope
    scope = TimeEntry.order('user_id, spent_on').where(:time_entries => {:issue_id => nil})
    add_scope_conditions(scope)
  end

  def get_issue_scope
    scope = Issue.includes(:time_entries).references(:time_entries).where(TimeEntry.arel_table[:hours].gt(0))
    add_scope_conditions(scope)
  end

end
