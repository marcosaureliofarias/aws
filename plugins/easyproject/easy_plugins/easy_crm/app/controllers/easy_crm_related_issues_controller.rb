class EasyCrmRelatedIssuesController < ApplicationController

  before_action :find_easy_crm_case
  before_action :find_project
  before_action :find_issue, :only => [:create, :destroy]
  before_action :authorize

  helper :easy_crm
  include EasyCrmHelper
  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper
  helper :custom_fields
  include CustomFieldsHelper

  def index
    if params[:q].present? && (m = params[:q].match(/^\d{1,9}$/))
      scope = Issue.open.visible.non_templates.where(id: m.to_s)
    else
      scope = Issue.open.visible.non_templates.limit(per_page_option).order(:lft)
      scope = scope.like(params[:q]) unless params[:q].blank?
    end

    @issues = scope.to_a

    respond_to do |format|
      format.html {render :partial => 'related_issues_list', :locals => {:issues => @issues, :project => @project, :easy_crm_case => @easy_crm_case}}
      format.js
    end
  end

  def create
    @easy_crm_case.issues << @issue unless @easy_crm_case.issues.include?(@issue)

    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_update)
        redirect_back_or_default easy_crm_case_path(@easy_crm_case)
      }
    end
  end

  def destroy
    @easy_crm_case.issues.delete @issue
    flash[:notice] = l(:notice_successful_delete)
    redirect_back_or_default easy_crm_case_path(@easy_crm_case)
  end

  private

  def find_easy_crm_case
    @easy_crm_case = EasyCrmCase.visible.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    @project = @easy_crm_case.project unless @easy_crm_case.nil?
    @project ||= (Project.find(params[:project_id]) unless params[:project_id].blank?)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_issue
    @issue = Issue.visible.find(params[:issue_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
