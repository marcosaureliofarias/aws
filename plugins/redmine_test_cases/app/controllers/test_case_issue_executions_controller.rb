class TestCaseIssueExecutionsController < TestCasesBaseController

  menu_item :test_cases

  before_action :find_test_case_issue_execution, :only => [:show, :edit, :update]
  before_action :find_test_case_issue_executions, :only => [:context_menu, :bulk_edit, :bulk_update, :destroy]
  before_action :find_test_case, :only => [:new, :create]
  before_action :find_project
  before_action :authorize_test_cases

  helper :attachments
  helper :context_menus
  helper :custom_fields
  helper :issues
  helper :test_case_issue_executions
  include_query_helpers

  accept_api_auth :index, :show, :create, :update, :destroy

  def index
    index_for_easy_query(TestCaseIssueExecutionQuery)
  end

  def show
    respond_to do |format|
      format.js
      format.html
      format.api
    end
  end

  def new
    @test_case_issue_execution = TestCaseIssueExecution.new(author: User.current, test_case: @test_case)
    @test_case_issue_execution.safe_attributes = params[:test_case_issue_execution]

    respond_to do |format|
      format.html
    end
  end

  def create
    @test_case_issue_execution = TestCaseIssueExecution.new(author: User.current, test_case: @test_case)
    @test_case_issue_execution.safe_attributes = params[:test_case_issue_execution]
    @test_case_issue_execution.save_attachments(params[:attachments] || (params[:test_case_issue_execution] && params[:test_case_issue_execution][:uploads]))

    if @test_case_issue_execution.save
      respond_to do |format|
        format.html {
          if params[:report_issue] == 'true'
            redirect_to new_project_issue_path(@project, issue: { test_case_ids: [@test_case_issue_execution.test_case_id] }, test_case_issue_execution_id: @test_case_issue_execution.id)
          else
            flash[:notice] = l(:notice_successful_create)
            redirect_back_or_default test_case_issue_execution_path(@test_case_issue_execution)
          end
        }
        format.api { render :action => 'show', :status => :created, :location => test_case_issue_execution_url(@test_case_issue_execution) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api { render_validation_errors(@test_case_issue_execution) }
      end
    end
  end

  def edit
    @test_case_issue_execution.safe_attributes = params[:test_case_issue_execution]

    respond_to do |format|
      format.js
      format.html
    end
  end

  def update
    @test_case_issue_execution.safe_attributes = params[:test_case_issue_execution]
    @test_case_issue_execution.save_attachments(params[:attachments] || (params[:test_case_issue_execution] && params[:test_case_issue_execution][:uploads]))

    if @test_case_issue_execution.save
      respond_to do |format|
        format.html {
          if params[:report_issue] == 'true'
            redirect_to new_project_issue_path(@project, issue: { test_case_ids: [@test_case_issue_execution.test_case_id] }, test_case_issue_execution_id: @test_case_issue_execution.id)
          else
            flash[:notice] = l(:notice_successful_update)
            redirect_back_or_default test_case_issue_execution_path(@test_case_issue_execution)
          end
        }
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api { render_validation_errors(@test_case_issue_execution) }
      end
    end
  end

  def destroy
    @test_case_issue_executions.each do |test_case_issue_execution|
      test_case_issue_execution.destroy
    end

    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default test_case_issue_executions_path(project_id: @project)
      end
      format.api { render_api_ok }
      format.js
    end
  end

  def bulk_edit
  end

  def bulk_update
    @test_case_issue_executions.each do |test_case_issue_execution|
      test_case_issue_execution.safe_attributes = params[:test_case_issue_execution]
      test_case_issue_execution.save
    end
    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_updated)
        redirect_back_or_default test_case_issue_executions_path(project_id: @project)
      end
    end
  end

  def context_menu
    if @test_case_issue_executions.size == 1
      @test_case_issue_execution = @test_case_issue_executions.first
    end
    @test_case_issue_execution_ids = @test_case_issue_executions.map(&:id).sort

    can_edit = @test_case_issue_executions.detect{|c| !c.editable?}.nil?
    can_delete = @test_case_issue_executions.detect{|c| !c.deletable?}.nil?
    @can = {edit: can_edit, delete: can_delete}
    @back = back_url

    @safe_attributes = @test_case_issue_executions.map(&:safe_attribute_names).reduce(:&)

    render layout: false
  end

  def autocomplete
  end

  def authors_autocomplete
    render json: User.sorted.like("%#{params[:term].to_s}%").limit(EasySetting.value('easy_select_limit').presence || 25).collect{|x| { value: x.name, id: x.id }}
  end

  private

  def find_test_case_issue_execution
    @test_case_issue_execution = TestCaseIssueExecution.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_test_case_issue_executions
    @test_case_issue_executions = TestCaseIssueExecution.visible.where(:id => (params[:id] || params[:ids])).to_a
    raise ActiveRecord::RecordNotFound if @test_case_issue_executions.empty?
    raise Unauthorized unless @test_case_issue_executions.all?(&:visible?)
    @projects = @test_case_issue_executions.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_test_case
    @test_case = TestCase.find(params[:test_case_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    @project ||= @test_case.try(:project) || @test_case_issue_execution.try(:project)
    @project ||= Project.find(params[:project_id]) if params[:project_id].present?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
