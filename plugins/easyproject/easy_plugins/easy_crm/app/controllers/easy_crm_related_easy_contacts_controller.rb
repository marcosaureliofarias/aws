class EasyCrmRelatedEasyContactsController < ApplicationController

  before_action :find_easy_crm_case
  before_action :find_project
  before_action :find_easy_contact, :only => [:create, :destroy]
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
    scope = EasyContact.visible.preload(:custom_values)
    scope = scope.like(params[:q]) unless params[:q].blank?
    scope = scope.limit(per_page_option)
    @easy_contacts = scope.to_a

    respond_to do |format|
      format.html {render :partial => 'related_easy_contacts_list', :locals => {:easy_contacts => @easy_contacts, :project => @project, :easy_crm_case => @easy_crm_case}}
      format.js
    end
  end

  def create
    @easy_crm_case.easy_contacts << @easy_contact unless @easy_crm_case.easy_contacts.include?(@easy_contact)

    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_update)
        redirect_back_or_default easy_crm_case_path(@easy_crm_case)
      }
      format.json {render(:json => {:notice => l(:notice_successful_update)})}
    end
  end

  def destroy
    @easy_crm_case.easy_contacts.delete @easy_contact
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

  def find_easy_contact
    @easy_contact = EasyContact.visible.find(params[:easy_contact_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
