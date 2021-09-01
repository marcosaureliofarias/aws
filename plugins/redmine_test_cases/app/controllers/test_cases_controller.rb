class TestCasesController < TestCasesBaseController

  menu_item :test_cases

  before_action :find_test_case, :only => [:show, :edit, :update]
  before_action :find_test_cases, :only => [:context_menu, :bulk_edit, :bulk_update, :destroy]
  before_action :find_project
  before_action :authorize_test_cases

  helper :attachments
  helper :context_menus
  helper :custom_fields
  helper :issues
  helper :test_cases
  include CustomFieldsHelper
  helper :easy_page_modules
  helper :easy_icons
  include EasyPageModulesHelper
  include_query_helpers

  accept_api_auth :index, :show, :create, :update, :destroy, :autocomplete, :issues_autocomplete

  def index
    index_for_easy_query(TestCaseQuery)
  end

  def show
    respond_to do |format|
      format.html
      format.api
    end
  end

  def new
    @test_case = TestCase.new(author: User.current, project: @project)
    @test_case.safe_attributes = params[:test_case]

    respond_to do |format|
      format.html
    end
  end

  def create
    @test_case = TestCase.new(author: User.current, project: @project)
    @test_case.safe_attributes = params[:test_case]
    @test_case.save_attachments(params[:attachments] || (params[:test_case] && params[:test_case][:uploads]))

    if @test_case.save
      @test_case.issues.each do |issue|
        issue.test_case_issue_executions.create(test_case: @test_case, author: User.current)
      end
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default test_case_path(@test_case)
        }
        format.api { render :action => 'show', :status => :created, :location => test_case_url(@test_case) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api { render_validation_errors(@test_case) }
      end
    end
  end

  def edit
    @test_case.safe_attributes = params[:test_case]

    respond_to do |format|
      format.html
    end
  end

  def update
    @test_case.safe_attributes = params[:test_case]
    @test_case.save_attachments(params[:attachments] || (params[:test_case] && params[:test_case][:uploads]))

    if @test_case.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default test_case_path(@test_case)
        }
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api { render_validation_errors(@test_case) }
      end
    end
  end

  def destroy
    @test_cases.each do |test_case|
      test_case.destroy!
    end

    respond_to do |format|
      format.js
      format.html {
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default test_cases_path(project_id: @project)
      }
      format.api { render_api_ok }
    end
  end

  def bulk_edit
  end

  def bulk_update
  end

  def context_menu
    if @test_cases.size == 1
      @test_case = @test_cases.first
    end
    @test_case_ids = @test_cases.map(&:id).sort

    can_edit = @test_case && @test_case.editable? # @test_cases.detect{|c| !c.editable?}.nil?
    can_delete = @test_cases.detect{|c| !c.deletable?}.nil?
    @can = {edit: can_edit, delete: can_delete}
    @back = back_url

    @safe_attributes = @test_cases.map(&:safe_attribute_names).reduce(:&)

    if params[:back_url] =~ /issues\/(\d+)$/
      @issue = Issue.find_by(id: $1)
    end

    render layout: false
  end

  def autocomplete
    render json: TestCase.visible.like(params[:term]).where(project: @project).limit(EasySetting.value('easy_select_limit').presence || 25).order(:name).to_a.map{|t| {value: t.name, id: t.id}}
  end

  def issues_autocomplete
    render json: Issue.visible.includes(:project).where(projects: { easy_is_easy_template: false, id: Project.has_module(:test_cases) }).like(params[:term]).limit(EasySetting.value('easy_select_limit').presence || 25).order(:subject).to_a.map{|t| {value: "#{t.id} #{t.project.name}: #{t.subject}", id: t.id}}
  end

  def statistics
    render_action_as_easy_page(EasyPage.find_by(page_name: 'statistics-test-cases'), nil, nil, statistics_test_cases_path(t: params[:t]), false, {})
  end

  def statistics_layout
    render_action_as_easy_page(EasyPage.find_by(page_name: 'statistics-test-cases'), nil, nil, statistics_test_cases_path(t: params[:t]), true, {})
  end

  private

  def find_test_case
    @test_case = TestCase.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_test_cases
    @test_cases = TestCase.visible.where(:id => (params[:id] || params[:ids])).to_a
    raise ActiveRecord::RecordNotFound if @test_cases.empty?
    raise Unauthorized unless @test_cases.all?(&:visible?)
    @projects = @test_cases.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    @project ||= @test_case.project if @test_case.present?
    @project ||= Project.find(params[:project_id]) if params[:project_id].present?
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
