class EasyButtonsController < ApplicationController

  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper
  helper :context_menus

  before_action :find_easy_button_instance, only: [:execute]
  before_action :build_easy_button, only: [:new, :create, :update_form]
  before_action :find_easy_button, only: [:copy, :edit, :update, :destroy]
  before_action :find_easy_buttons, only: [:context_menu, :bulk_destroy]
  before_action :find_entity, only: [:execute]
  before_action :authorize_global

  def index
    index_for_easy_query(EasyButtonQuery, [], conditions: EasyButton.visible_conditions_for_manage)
  end

  def new
  end

  def copy
    @easy_button = @easy_button.dup

    respond_to do |format|
      format.html { render :new }
    end
  end

  def create
    respond_to do |format|
      if @easy_button.save
        format.html do
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default easy_buttons_path
        end
      else
        format.html { render :new }
      end
    end
  end

  def edit
  end

  def update
    @easy_button.safe_attributes = params[:easy_button]

    if @easy_button.save
      flash[:notice] = l(:notice_successful_update)

      respond_to do |format|
        format.html do
          redirect_back_or_default easy_buttons_path
        end
      end
    else
      respond_to do |format|
        format.html { render :edit }
      end
    end
  end

  def update_form
    respond_to do |format|
      format.js
    end
  end

  def destroy
    if @easy_button.editable?
      @easy_button.safe_destroy
    end

    redirect_back_or_default easy_buttons_path
  end

  def execute
    respond_to do |format|
      format.js
    end
  end

  def context_menu
    render layout: false
  end

  def bulk_destroy
    destroyed = []

    @easy_buttons.each do |button|
      if button.editable? && button.safe_destroy
        destroyed << button
      end
    end

    respond_to do |format|
      format.html do
        flash[:notice] = "(#{destroyed.size}) #{l(:label_deleted)}"
        redirect_back_or_default easy_buttons_path
      end
    end
  end

  private

    def find_easy_button
      @easy_button = EasyButton.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def find_easy_button_instance
      EasyButton.reload_buttons
      @easy_button = EasyButton.get(params[:id])

      render_404 if @easy_button.blank?
    end

    def find_entity
      @entity = @easy_button.entity_class.find(params[:entity_id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def find_easy_buttons
      @easy_buttons = EasyButton.visible.active.visible_for_manage.where(id: params[:ids])
    end

    def build_easy_button
      params[:easy_button] ||= {}
      type = params[:easy_button][:entity_type] || params[:entity_type]

      # Entity type must be set first
      @easy_button = EasyButton.new
      @easy_button.author = User.current
      @easy_button.entity_type = type
      @easy_button.safe_attributes = params[:easy_button]
    end

end
