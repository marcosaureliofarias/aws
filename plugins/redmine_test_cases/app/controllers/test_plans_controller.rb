class TestPlansController < TestCasesBaseController
  before_action :find_test_plan, :only => [:show, :edit, :update]
  before_action :find_test_plans, :only => [:destroy]
  before_action :find_project
  before_action :authorize_test_cases

  helper :issues
  helper :custom_fields
  include CustomFieldsHelper
  include_query_helpers

  def index
    index_for_easy_query(TestPlanQuery)
  end

  def show
    respond_to do |format|
      format.html
    end
  end

  def new
    @test_plan = TestPlan.new(author: User.current, project: @project)
    @test_plan.safe_attributes = params[:test_plan]

    respond_to do |format|
      format.html
    end
  end

  def create
    @test_plan = TestPlan.new(author: User.current, project: @project)
    @test_plan.safe_attributes = params[:test_plan]

    if @test_plan.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default polymorphic_path([@project, @test_plan])
        }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
      end
    end
  end

  def edit
    @test_plan.safe_attributes = params[:test_plan]

    respond_to do |format|
      format.html
    end
  end

  def update
    @test_plan.safe_attributes = params[:test_plan]
    if @test_plan.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default polymorphic_path([@project, @test_plan])
        }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
      end
    end
  end

  def destroy
    @test_plans.each do |test_plan|
      test_plan.destroy!
    end

    respond_to do |format|
      format.js
      format.html {
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default project_test_plans_path(@project)
      }
    end
  end

  def autocomplete
    render json: TestPlan.like(params[:term]).where(project: @project).limit(EasySetting.value('easy_select_limit').presence || 25).order(:name).to_a.map{|t| {value: t.name, id: t.id}}
  end

  private

  def find_test_plan
    @test_plan = TestPlan.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_test_plans
    @test_plans = TestPlan.where(:id => (params[:id] || params[:ids])).to_a
    raise ActiveRecord::RecordNotFound if @test_plans.empty?
    raise Unauthorized unless @test_plans.all?(&:visible?)
    @projects = @test_plans.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    @project = @test_plan.project if @test_plan.present?
    @project = Project.find(params[:project_id]) if !@project.present? && params[:project_id].present?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
