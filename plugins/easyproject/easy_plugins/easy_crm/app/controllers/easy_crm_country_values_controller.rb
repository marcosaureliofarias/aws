class EasyCrmCountryValuesController < ApplicationController

  menu_item :easy_crm

  before_action :find_easy_crm_country_value, :only => [:show, :edit, :update]
  before_action :find_easy_crm_country_values, :only => [:context_menu, :bulk_edit, :bulk_update, :destroy]
  before_action :authorize_global

  helper :easy_crm_country_values
  helper :custom_fields
  helper :attachments
  helper :issues
  include_query_helpers

  accept_api_auth :index, :show, :create, :update, :destroy

  def index
    index_for_easy_query(EasyCrmCountryValueQuery)
  end

  def show
    respond_to do |format|
      format.html
      format.api
    end
  end

  def new
    @easy_crm_country_value = EasyCrmCountryValue.new
    @easy_crm_country_value.safe_attributes = params[:easy_crm_country_value]

    respond_to do |format|
      format.html
    end
  end

  def create
    @easy_crm_country_value = EasyCrmCountryValue.new
    @easy_crm_country_value.safe_attributes = params[:easy_crm_country_value]

    if @easy_crm_country_value.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default easy_crm_country_values_path
        }
        format.api { render :action => 'show', :status => :created, :location => easy_crm_country_value_url(@easy_crm_country_value) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api { render_validation_errors(@easy_crm_country_value) }
      end
    end
  end

  def edit
    @easy_crm_country_value.safe_attributes = params[:easy_crm_country_value]

    respond_to do |format|
      format.html
    end
  end

  def update
    @easy_crm_country_value.safe_attributes = params[:easy_crm_country_value]

    if @easy_crm_country_value.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default easy_crm_country_values_path
        }
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api { render_validation_errors(@easy_crm_country_value) }
      end
    end
  end

  def destroy
    @easy_crm_country_values.each do |easy_crm_country_value|
      easy_crm_country_value.destroy
    end

    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default easy_crm_country_values_path
      }
      format.api { render_api_ok }
    end
  end

  def bulk_edit
  end

  def bulk_update
  end

  def context_menu
    if (@easy_crm_country_values.size == 1)
      @easy_crm_country_value = @easy_crm_country_values.first
    end
    @easy_crm_country_value_ids = @easy_crm_country_values.map(&:id).sort

    can_edit = @easy_crm_country_values.detect{|c| !c.editable?}.nil?
    can_delete = @easy_crm_country_values.detect{|c| !c.deletable?}.nil?
    @can = {:edit => can_edit, :delete => can_delete}
    @back = back_url

    @safe_attributes = @easy_crm_country_values.map(&:safe_attribute_names).reduce(:&)

    render :layout => false
  end

  def autocomplete
  end

  private

  def find_easy_crm_country_value
    @easy_crm_country_value = EasyCrmCountryValue.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_easy_crm_country_values
    @easy_crm_country_values = EasyCrmCountryValue.visible.where(:id => (params[:id] || params[:ids])).to_a
    raise ActiveRecord::RecordNotFound if @easy_crm_country_values.empty?
    raise Unauthorized unless @easy_crm_country_values.all?(&:visible?)
    @projects = @easy_crm_country_values.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
