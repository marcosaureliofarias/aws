class EasyCustomProjectMenusController < ApplicationController

  before_action :find_optional_project
  before_action :find_easy_custom_project_menu, :only => [:show, :edit, :update, :destroy]

  def index

  end

  def show

  end

  def new
    @easy_custom_project_menu                 = EasyCustomProjectMenu.new
    @easy_custom_project_menu.project         = @project
    @easy_custom_project_menu.safe_attributes = params[:easy_custom_project_menu]

    respond_to do |format|
      format.js
    end
  end

  def create
    @easy_custom_project_menu                 = EasyCustomProjectMenu.new
    @easy_custom_project_menu.project         = @project
    @easy_custom_project_menu.safe_attributes = params[:easy_custom_project_menu]

    if @easy_custom_project_menu.save
      respond_to do |format|
        format.js { render :template => 'common/close_modal' }
      end
    else
      respond_to do |format|
        format.js { render :action => 'new' }
      end
    end
  end

  def edit
    @easy_custom_project_menu.safe_attributes = params[:easy_custom_project_menu]

    respond_to do |format|
      format.js
    end
  end

  def update
    @easy_custom_project_menu.safe_attributes = params[:easy_custom_project_menu]

    if @easy_custom_project_menu.save
      respond_to do |format|
        format.js { render :template => 'common/close_modal' }
      end
    else
      respond_to do |format|
        format.js { render :action => 'edit' }
      end
    end
  end

  def destroy
    @easy_custom_project_menu.destroy

    respond_to do |format|
      format.html { redirect_to back_url }
    end
  end

  private

  def find_easy_custom_project_menu
    @easy_custom_project_menu = EasyCustomProjectMenu.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
