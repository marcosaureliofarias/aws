class EasyCrmCaseItemsController < ApplicationController

  menu_item :easy_crm

  before_action :find_easy_crm_case_item, :only => [:show, :edit, :update, :destroy]
  before_action :find_easy_crm_case_items, :only => [:context_menu, :bulk_destroy]
  before_action :find_easy_crm_case, :only => [:edit_easy_crm_case_items, :update_easy_crm_case_items]

  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :context_menus
  include ContextMenusHelper
  helper :easy_crm
  include EasyCrmHelper

  accept_api_auth :index, :show, :create, :update, :destroy, :bulk_destroy

  def index
    index_for_easy_query EasyCrmCaseItemQuery, [['name', 'asc']]
  end

  def show
    respond_to do |format|
      format.api
    end
  end

  def new
    @easy_crm_case_item = EasyCrmCaseItem.new
    @easy_crm_case_item.safe_attributes = params[:easy_crm_case_item]

    respond_to do |format|
      format.html
    end
  end

  def create
    @easy_crm_case_item = EasyCrmCaseItem.new
    @easy_crm_case_item.safe_attributes = params[:easy_crm_case_item]

    if @easy_crm_case_item.save
      respond_to do |format|
        format.html { redirect_back_or_default easy_crm_case_item_path(@easy_crm_case_item) }
        format.api { render :action => 'show', :status => :created, :location => easy_crm_case_item_url(@easy_crm_case_item) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api { render_validation_errors(@easy_crm_case_item) }
      end
    end
  end

  def edit
    @easy_crm_case_item.safe_attributes = params[:easy_crm_case_item]

    respond_to do |format|
      format.html
    end
  end

  def update
    @easy_crm_case_item.safe_attributes = params[:easy_crm_case_item]

    if @easy_crm_case_item.save
      respond_to do |format|
        format.html { redirect_back_or_default easy_crm_case_item_path(@easy_crm_case_item) }
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api { render_validation_errors(@easy_crm_case_item) }
      end
    end
  end

  def destroy
    @easy_crm_case_item.destroy

    respond_to do |format|
      format.js
      format.html { redirect_back_or_default easy_crm_case_path(@easy_crm_case) }
      format.api { render_api_ok }
    end
  end

  def bulk_destroy
    @easy_crm_case_items.destroy_all

    respond_to do |format|
      format.html { redirect_back_or_default easy_crm_case_items_path }
      format.api { render_api_ok }
    end
  end

  def edit_easy_crm_case_items
    respond_to do |format|
      format.js
    end
  end

  def update_easy_crm_case_items
    @easy_crm_case.safe_attributes = params[:easy_crm_case]
    @easy_crm_case_saved = @easy_crm_case.save

    respond_to do |format|
      format.js
    end
  end

  def context_menu
    @easy_crm_case = @easy_crm_case_items.first.easy_crm_case
    render :layout => false
  end

  private

  def find_easy_crm_case_item
    @easy_crm_case_item = EasyCrmCaseItem.find(params[:id])
    @easy_crm_case = @easy_crm_case_item.easy_crm_case
    @project = @easy_crm_case.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_easy_crm_case_items
    @easy_crm_case_items = EasyCrmCaseItem.where(:id => (params[:id] || params[:ids]))
    return render_404 if @easy_crm_case_items.empty?
  end

  def find_easy_crm_case
    @easy_crm_case = EasyCrmCase.find(params[:id])
    @project = @easy_crm_case.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
