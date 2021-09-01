class EasyUserTypesController < ApplicationController

  layout 'admin'

  before_action { |c| c.require_admin_or_lesser_admin(:easy_user_types) }
  before_action :find_easy_user_type, only: [:show, :edit, :update, :destroy]
  before_action :find_easy_custom_menu, only: [:reorder_custom_menus]
  accept_api_auth :index, :show, :create, :update, :destroy

  def index
    @easy_user_types = EasyUserType.sorted
    respond_to do |format|
      format.html {
        @pages, @types = paginate @easy_user_types

        if request.xhr? && @pages.last_page.to_i < params['page'].to_i
          render_404
        else
          render :action => 'index', :layout => false if request.xhr?
        end
      }
      format.api { render :api => @easy_user_types }
    end
  end

  def show
    respond_to do |format|
      format.api { render :api => @easy_user_type }
    end
  end

  def new
    @easy_user_type = EasyUserType.new(params[:easy_user_type])
    respond_to do |format|
      format.html
    end
  end

  def edit
    @easy_user_type.is_copy = params[:is_copy] if params[:is_copy]
    respond_to do |format|
      format.html
    end
  end

  def create
    @easy_user_type                 = EasyUserType.new
    @easy_user_type.safe_attributes = params[:easy_user_type]
    if @easy_user_type.save
      respond_to do |format|
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_to easy_user_types_path }
        format.api { render :action => 'show', :status => :created, :location => easy_user_type_url(@easy_user_type) }
      end
    else
      respond_to do |format|
        format.html { render action: :new }
        format.api { render_validation_errors(@easy_user_type) }
      end
    end
  end

  def update
    @easy_user_type.safe_attributes = params[:easy_user_type]
    @easy_user_type                 = @easy_user_type.copy if @easy_user_type.is_copy.to_boolean
    if @easy_user_type.save
      respond_to do |format|

        format.html do
          flash[:notice] = l(:notice_successful_update) if params[:easy_user_type] && params[:easy_user_type][:reorder_to_position].blank?
          redirect_to easy_user_types_path
        end
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render action: :edit }
        format.api { render_validation_errors(@easy_user_type) }
      end
    end
  end

  def destroy
    if @easy_user_type.is_default?
      flash[:error] = l(:error_cant_remove_default_type)
      respond_to do |format|
        format.html { redirect_to easy_user_types_path }
        format.api { render_validation_errors(@easy_user_type) }
      end
    else
      @easy_user_type.destroy
      respond_to do |format|
        format.html { redirect_to easy_user_types_path }
        format.api { render_api_ok }
      end
    end
  end

  def reorder_custom_menus
    @easy_custom_menu.position = params[:easy_custom_menu][:reorder_to_position] if params[:easy_custom_menu]
    respond_to do |format|
      if @easy_custom_menu.save
        format.api { render_api_ok }
      else
        format.api { render_validation_errors(@easy_custom_menu) }
      end
    end
  end

  private

  def find_easy_custom_menu
    @easy_custom_menu = EasyCustomMenu.find(params[:easy_custom_menu_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_easy_user_type
    @easy_user_type = EasyUserType.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
