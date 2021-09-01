class EasyCrmRelatedEasyInvoicesController < ApplicationController

  before_action :find_easy_crm_case
  before_action :find_project
  before_action :find_easy_invoice, :only => [:create, :destroy]
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
    query = EasyInvoiceQuery.new
    query.from_params(params)
    query.add_additional_statement("#{query.entity_table_name}.id NOT IN (#{@easy_crm_case.easy_invoices.select(:id).to_sql})")
    @easy_invoices = query.entities(:preload => [{:client => [:easy_contact_type]}, :easy_crm_case], :limit => per_page_option)

    respond_to do |format|
      format.html { render :partial => 'related_easy_invoices_list', :locals => {:easy_invoices => @easy_invoices, :project => @project, :easy_crm_case => @easy_crm_case} }
      format.js
      format.api { render :json => {:easy_invoices => @easy_invoices} }
    end
  end

  def create
    @easy_crm_case.easy_invoice_ids |= [@easy_invoice.id]

    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_update)
        redirect_back_or_default easy_crm_case_path(@easy_crm_case)
      }
      format.api { render_api_ok }
    end
  end

  def destroy
    @easy_crm_case.easy_invoices.delete @easy_invoice
    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default easy_crm_case_path(@easy_crm_case)
      }
      format.api { render_api_ok }
    end
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

  def find_easy_invoice
    @easy_invoice = EasyInvoice.visible.find(params[:easy_invoice_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
