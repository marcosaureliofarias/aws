class ApiRolesController < ApplicationController

  before_action :require_admin
  before_action :find_role, :only => [:show, :update, :destroy]

  accept_api_auth :index, :show, :create, :update, :destroy

  def index
    @roles = Role.order('builtin, position')
    respond_to do |format|
      format.api
    end
  end

  def show
    respond_to do |format|
      format.api
    end
  end

  def create
    @role                 = Role.new
    @role.safe_attributes = params[:role]
    if @role.save
      respond_to do |format|
        format.api { render :action => 'show', :status => :created, :location => url_for(:controller => 'api_roles', :action => 'show', :id => @role.id) }
      end
    else
      respond_to do |format|
        format.api { render_validation_errors(@role) }
      end
    end
  end

  def update
    @role.safe_attributes = params[:role]
    if @role.save
      respond_to do |format|
        format.api { head :ok }
      end
    else
      respond_to do |format|
        format.api { render_validation_errors(@role) }
      end
    end
  end

  def destroy
    @role.destroy
    respond_to do |format|
      format.api { head :ok }
    end
  end

  private

  def find_role
    @role = Role.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
