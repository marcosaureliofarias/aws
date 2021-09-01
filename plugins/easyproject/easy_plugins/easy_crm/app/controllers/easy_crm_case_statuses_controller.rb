class EasyCrmCaseStatusesController < ApplicationController

  menu_item :easy_crm

  before_action :find_optional_project
  before_action :authorize_global
  before_action :find_easy_crm_case_status, :only => [:show, :edit, :update, :destroy, :change]

  accept_api_auth :index, :show, :create, :update, :destroy

  helper :easy_crm
  include EasyCrmHelper
  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper

  def index
    @easy_crm_case_statuses = EasyCrmCaseStatus.sorted
    @limit = per_page_option
    @easy_crm_case_statuses_pages = Redmine::Pagination::Paginator.new @easy_crm_case_statuses.count, @limit, params['page']
    @offset ||= @easy_crm_case_statuses_pages.offset

    respond_to do |format|
      format.html
      format.api
    end
  end

  def show
    respond_to do |format|
      format.html
      format.api
    end
  end

  def new
    @easy_crm_case_status = EasyCrmCaseStatus.new
    @easy_crm_case_status.safe_attributes = params[:easy_crm_case_status]

    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @easy_crm_case_status = EasyCrmCaseStatus.new
    @easy_crm_case_status.safe_attributes = params[:easy_crm_case_status]

    if @easy_crm_case_status.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default(:action => 'index')
        }
        format.api  { render :action => 'show', :status => :created, :location => easy_crm_case_status_url(@easy_crm_case_status) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api { render_validation_errors(@easy_crm_case_status) }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    @easy_crm_case_status.safe_attributes = params[:easy_crm_case_status]

    if @easy_crm_case_status.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_update) if params[:easy_crm_case_status] && params[:easy_crm_case_status][:reorder_to_position].blank?
          redirect_back_or_default(:action => 'index')
        end
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api { render_validation_errors(@easy_crm_case_status) }
      end
    end
  end

  def destroy
    if @easy_crm_case_status.easy_crm_cases.any?
      respond_to do |format|
        format.html {
          flash[:notice] = l(:error_can_not_delete_easy_crm_status)
          redirect_to change_easy_crm_case_status_path(@easy_crm_case_status, request.query_parameters)
        }
        format.api { render_api_ok }
      end
    else
      @easy_crm_case_status.destroy

      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_delete)
          redirect_back_or_default(:action => 'index')
        }
        format.api { render_api_ok }
      end
    end
  end

  def change
    if request.post?
      unless params[:easy_crm_case_status_to_id].blank? || params[:easy_crm_case_status_to_id] == @easy_crm_case_status.id.to_s
        @easy_crm_case_status_to = EasyCrmCaseStatus.find(params[:easy_crm_case_status_to_id])
        @easy_crm_case_status.easy_crm_cases.update_all(:easy_crm_case_status_id => @easy_crm_case_status_to.id)
        if @easy_crm_case_status.easy_crm_cases.any?
          flash[:error] = l(:error_can_not_delete_easy_crm_status)
          redirect_to change_easy_crm_case_status_path(@easy_crm_case_status)
        else
          @easy_crm_case_status.destroy
          redirect_back_or_default(:action => 'index')
        end
      end
    else
      @easy_crm_case_statuses = EasyCrmCaseStatus.where("#{EasyCrmCaseStatus.table_name}.id <> ?", @easy_crm_case_status.id)
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private

  def find_easy_crm_case_status
    @easy_crm_case_status = EasyCrmCaseStatus.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
