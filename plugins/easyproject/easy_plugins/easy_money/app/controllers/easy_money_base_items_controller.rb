class EasyMoneyBaseItemsController < ApplicationController

  before_action :find_easy_money_object, :only => [:show, :edit, :update, :destroy]
  before_action :find_easy_money_project, except: [:bulk_edit, :bulk_update, :bulk_delete]
  before_action :check_for_project, :only => [:new, :create, :edit, :update]
  before_action :find_easy_moneys, :only => [:bulk_edit, :bulk_update, :bulk_delete]
  before_action :authorize_global
  before_action :add_price2, :only => [:create, :update]
  before_action :price_validation, :only => [:create, :update]
  before_action :load_current_easy_currency_code, only: [:show, :inline_edit, :inline_update]
  accept_api_auth :index, :show, :create, :update, :destroy

  helper :easy_query
  include EasyQueryHelper
  helper :easy_money
  include EasyMoneyHelper
  helper :attachments
  include AttachmentsHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :projects
  include ProjectsHelper
  helper :sort
  include SortHelper

  def index
    retrieve_query(easy_money_query)
    sort_init(@query.sort_criteria_init)
    sort_update(@query.sortable_columns)

    @money_entity_type = easy_money_entity_relation

    @query.entity_to_statement = @entity if @entity

    prepare_easy_query_render

    if request.xhr? && !@entities
      render_404
      return false
    end

    respond_to do |format|
      format.html {
        render_easy_query_html
      }
      format.api
      format.csv {send_data(export_to_csv(@entities, @query), :filename => get_export_filename(:csv, @query, l("label_easy_money_#{@money_entity_type.to_sym}")))}
      format.pdf {
        label = l("label_easy_money_#{@money_entity_type.to_sym}")
        send_file_headers! :type => 'application/pdf', :filename => get_export_filename(:pdf, @query, label)
        render 'easy_money_base_items/index', default_title: label
      }
      format.xlsx {
        label = l("label_easy_money_#{@money_entity_type.to_sym}")
        send_data(export_to_xlsx(@entities, @query, :default_title => label), :filename => get_export_filename(:xlsx, @query, label))
      }
    end
  end

  def show
    respond_to do |format|
      format.html { render 'easy_money_base_items/show' }
      format.api
    end
  end

  def new
    @easy_money_object = easy_money_entity_class.new
    @easy_money_object.safe_attributes = params[:easy_money] if params[:easy_money]
    @easy_money_object.spent_on ||= Date.today

    respond_to do |format|
      format.html
    end
  end

  def create
    @easy_money_object = easy_money_entity_class.new
    @easy_money_object.safe_attributes = params[:easy_money] if params[:easy_money]
    unless @easy_money_object.easy_currency_code?
      @easy_money_object.easy_currency_code = @project.easy_currency_code.presence || EasyCurrency.default_code
    end

    if @easy_money_object.save
      attachments = Attachment.attach_files(@easy_money_object, params[:attachments])
      Redmine::Hook.call_hook("controller_easy_money_#{easy_money_entity_relation}_create_after_save".to_sym, {easy_money_entity_relation.to_sym => @easy_money_object, :attachments => attachments, :params => params})

      respond_to do |format|
        format.html {
          render_attachment_warning_if_needed(@easy_money_object)
          flash[:notice] = l(:notice_successful_create)
          params[:continue] ?
            redirect_to(:action => 'new', :project_id => @project, :'easy_money[entity_type]' => @easy_money_object.entity_type, :'easy_money[entity_id]' => @easy_money_object.entity_id ) :
            redirect_back_or_default(:action => 'index', :project_id => @project, :'easy_money[entity_type]' => @easy_money_object.entity_type, :'easy_money[entity_id]' => @easy_money_object.entity_id)
        }
        format.api  {
          render :action => 'show', :status => :created,
                 :location => url_for(:action => 'show', :id => @easy_money_object.id, :project_id => @project.id, :'easy_money[entity_type]' => @easy_money_object.entity_type, :'easy_money[entity_id]' => @easy_money_object.entity_id) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@easy_money_object) }
      end
    end

  end

  def edit
    flash[:warning] = l(:warning_model_has_easy_external_id) if @easy_money_object.easy_external_id
    respond_to do |format|
      format.html
    end
  end

  def update
    @easy_money_object.safe_attributes = params[:easy_money] if params[:easy_money]

    if @easy_money_object.save
      attachments = Attachment.attach_files(@easy_money_object, params[:attachments])
      Redmine::Hook.call_hook("controller_easy_money_#{easy_money_entity_relation}_update_after_save".to_sym, {easy_money_entity_relation.to_sym => @easy_money_object, :attachments => attachments, :params => params})

      respond_to do |format|
        format.html {
          render_attachment_warning_if_needed(@easy_money_object)
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default(:action => 'index', :project_id => @project, :'easy_money[entity_type]' => @easy_money_object.entity_type, :'easy_money[entity_id]' => @easy_money_object.entity_id)
        }
        format.api  { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api  { render_validation_errors(@easy_money_object) }
      end
    end
  end

  def destroy
    @easy_money_object.destroy

    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default(:action => 'index', :project_id => @project, :'easy_money[entity_type]' => @easy_money_object.entity_type, :'easy_money[entity_id]' => @easy_money_object.entity_id)
      }
      format.api  { render_api_ok }
    end
  end

  def inline_edit
    respond_to do |format|
      format.js
    end
  end

  def inline_update(entity)
    if @project.easy_money_settings.expected_count_price == 'price1'
      price1 = params[easy_money_entity_relation.to_sym][:price].to_f
      price2 = EasyMoneyEntity.compute_price2(@project, price1)
    else
      price2 = params[easy_money_entity_relation.to_sym][:price].to_f
      price1 = EasyMoneyEntity.compute_price1(@project, price2)
    end

    Redmine::Hook.call_hook(:controller_easy_money_base_item_inline_update_before_change, easy_money_object: entity, params: params, easy_money_entity_relation: easy_money_entity_relation)

    entity.price1 = price1
    entity.vat = @project.easy_money_settings.vat.to_f
    entity.price2 = price2
    entity.easy_currency_code = @current_easy_currency_code
    entity.save(:validate => false)

    respond_to do |format|
      format.js
    end
  end

  def bulk_edit
    @custom_fields = @easy_moneys.map(&:editable_custom_fields).reduce(:&)
    if @custom_fields
      @custom_fields.uniq!
    else
      @custom_fields = []
    end
  end

  def bulk_update
    unsaved_money = []
    saved_money = []
    errors = []

    attributes = parse_params_for_bulk_entity_attributes(params['easy_money_entity_class'])

    @easy_moneys.each do |money|
      Redmine::Hook.call_hook(:controller_easy_money_base_item_bulk_update_before_change, easy_money_object: money, params: params, easy_money_entity_relation: easy_money_entity_relation)

      money.safe_attributes = attributes
      if money.save
        saved_money << money
      else
        unsaved_money << money
        errors << money.errors.full_messages
      end
    end

    respond_to do |format|
      format.js {
        if errors.any?
          @flash_message = errors.join(', ')
        else
          @flash_message = l(:notice_successful_update)
        end
      }
      format.html {
        if errors.any?
          @unsaved_money = unsaved_money
          @saved_money = saved_money
          bulk_edit
          render :action => 'bulk_edit'
        else
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default(:action => 'index')
        end
      }
    end
  end

  def bulk_delete
    @easy_moneys.each do |money|
      Redmine::Hook.call_hook(:controller_easy_money_base_item_bulk_delete_before_delete, easy_money_object: money, params: params, easy_money_entity_relation: easy_money_entity_relation)
      money.destroy
    end

    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default action: 'index', project_id: @projects.first
      }
      format.api { render_api_ok }
    end
  end

  private

  def find_easy_moneys
    if params[:ids]
      @easy_moneys = easy_money_entity_class.where(:id => params[:ids])
      @projects = @easy_moneys.map(&:project).uniq
    else
      render_404
    end
  end

  def check_for_project
    render_404 unless @project
  end

  def check_setting_show_expected
    render_404 if @project && !@project.easy_money_settings.show_expected?
  end

  def find_easy_money_object
    @easy_money_object = easy_money_entity_class.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def easy_money_entity_class
    raise NotImplementedError, 'You have to override this method.'
  end

  def easy_money_entity_relation
    raise NotImplementedError, 'You have to override this method.'
  end

  def easy_money_query
    raise NotImplementedError, 'You have to override this method.'
  end

end
