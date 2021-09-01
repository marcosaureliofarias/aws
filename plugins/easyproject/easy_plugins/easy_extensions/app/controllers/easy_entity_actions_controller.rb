class EasyEntityActionsController < ApplicationController

  before_action :find_easy_entity_action, :only => [:show, :edit, :update, :destroy, :execute, :execute_all]
  before_action :find_entity, :only => [:execute]
  before_action :authorize_global
  before_action :create_easy_entity_action, :only => [:new, :create, :update_form]
  before_action :create_easy_query, :only => [:show, :new, :edit, :update_form]

  helper :easy_entity_actions
  include EasyEntityActionsHelper
  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper
  helper :custom_fields

  def index
    index_for_easy_query EasyEntityActionQuery, [['name', 'asc']]
  end

  def show
    sort_init(@query.sort_criteria.empty? ? [] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.group_by = nil

    respond_to do |format|
      format.html
    end
  end

  def new
    respond_to do |format|
      format.html
    end
  end

  def create
    if @easy_entity_action.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default easy_entity_actions_path
        }
      end
    else
      create_easy_query
      respond_to do |format|
        format.html { render :action => 'new' }
      end
    end
  end

  def edit
    @easy_entity_action.safe_attributes = params[:easy_entity_action]

    respond_to do |format|
      format.html
    end
  end

  def update
    @easy_entity_action.safe_attributes = params[:easy_entity_action]

    if @easy_entity_action.save
      flash[:notice] = l(:notice_successful_update)

      respond_to do |format|
        format.html {
          redirect_back_or_default easy_entity_actions_path
        }
      end
    else
      create_easy_query
      respond_to do |format|
        format.html { render :action => 'edit' }
      end
    end
  end

  def destroy
    @easy_entity_action.destroy
    flash[:notice] = l(:notice_successful_delete)

    respond_to do |format|
      format.html {
        redirect_back_or_default easy_entity_actions_path
      }
    end
  end

  def update_form
    respond_to do |format|
      format.js
    end
  end

  def execute
    @easy_entity_action.execute(@entity)

    redirect_back_or_default easy_entity_action_path(@easy_entity_action)
  end

  def execute_all
    @easy_entity_action.execute_all

    redirect_back_or_default easy_entity_action_path(@easy_entity_action)
  end

  private

  def find_easy_entity_action
    @easy_entity_action = EasyEntityAction.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def create_easy_query
    @query = @easy_entity_action.create_easy_query
    render_404 if @query.nil? && !@easy_entity_action.new_record?
  end

  def find_entity
    entity_klass = begin
      params[:entity_type].constantize
    rescue
      nil
    end if params[:entity_type]

    @entity      = entity_klass.find(params[:entity_id]) if entity_klass && params[:entity_id]
    render_404 if !@entity
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def create_easy_entity_action
    eea_klass = begin
      params[:type].constantize if !params[:type].blank?
    rescue
      nil
    end

    if eea_klass && EasyEntityAction.registered_actions.include?(eea_klass.name)
      @easy_entity_action = eea_klass.new
    else
      @easy_entity_action = EasyEntityAction.new
    end

    @easy_entity_action.project         = @project
    @easy_entity_action.safe_attributes = params[:easy_entity_action]
    @easy_entity_action.author          ||= User.current
    @easy_entity_action.execute_as      ||= 'author'
  end

end
