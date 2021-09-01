class EasyCrmCaseMailTemplatesController < ApplicationController

  menu_item :easy_crm

  before_action :find_optional_project, :only => [:show, :update, :create, :destroy]
  before_action :find_easy_crm_case_mail_template, :only => [:show, :edit, :update, :destroy]
  before_action :authorize, :only => [:destroy]

  helper :sort
  include SortHelper

  def index
    sort_init 'easy_crm_case_status', 'asc'
    sort_update 'easy_crm_case_status' => "#{EasyCrmCaseStatus.table_name}.position"

    scope = EasyCrmCaseMailTemplate.includes(:easy_crm_case_status).references(:easy_crm_case_status).preload(:project)

    @limit = per_page_option
    @easy_crm_case_mail_templates_pages = Redmine::Pagination::Paginator.new scope.count, @limit, params['page']
    @offset ||= @easy_crm_case_mail_templates_pages.offset
    @easy_crm_case_mail_templates = scope.order(sort_clause).to_a

    respond_to do |format|
      format.html
    end
  end

  def show
    respond_to do |format|
      format.html
    end
  end

  def new
    @easy_crm_case_mail_template = EasyCrmCaseMailTemplate.new
    @easy_crm_case_mail_template.safe_attributes = params[:easy_crm_case_mail_template]
    respond_to do |format|
      format.html
    end
  end

  def create
    @easy_crm_case_mail_template = EasyCrmCaseMailTemplate.new
    @easy_crm_case_mail_template.safe_attributes = params[:easy_crm_case_mail_template]
    @easy_crm_case_mail_template.project_id = @project.id
    if @easy_crm_case_mail_template.save
      respond_to do |format|
        format.html  {
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default(:action => 'index')
        }
      end
    else
      respond_to do |format|
        format.html  { render :action => 'new' }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    @easy_crm_case_mail_template.safe_attributes = params[:easy_crm_case_mail_template]

    if @easy_crm_case_mail_template.save
      respond_to do |format|
        format.html  {
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default(:action => 'index')
        }
      end
    else
      respond_to do |format|
        format.html  { render :action => 'edit' }
      end
    end
  end

  def destroy
    @easy_crm_case_mail_template.destroy

    redirect_back_or_default(:action => 'index')
  end

  private

  def find_easy_crm_case_mail_template
    @easy_crm_case_mail_template = EasyCrmCaseMailTemplate.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
