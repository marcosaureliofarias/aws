class AlertTypesController < ApplicationController

  before_action :find_type, :only => [:show, :edit, :update, :destroy]
  before_action :authorize_global

  # GET /alert_types
  def index
    @types = AlertType.all
  end

  # GET /alert_types/:id
  # GET /alert_types/:id/show
  def show
  end

  # GET /alert_types/new
  def new
    @type = AlertType.new
  end

  # POST /alert_types
  def create
    @type = AlertType.new(params.require(:alert_type).permit!)

    respond_to do |format|
      if @type.save
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_to( :action => 'index' ) }
      else
        format.html { render :action => "new" }
      end
    end

  end

  # GET /alert_types/:id/edit
  def edit
  end

  # PUT /alert_types/:id
  def update
    respond_to do |format|
      if @type.update_attributes(params.require(:alert_type).permit!)
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_to( :action => 'index' ) }
        format.api { render_api_ok }
      else
        format.html { render :action => "edit" }
        format.api { render_validation_errors(@type) }
      end
    end
  end

  # DELETE /alert_types/:id
  def destroy
    @type.destroy

    respond_to do |format|
      flash[:notice] = l(:notice_successful_delete)
      format.html { redirect_to( :action => 'index' ) }
    end
  end


private

  def find_type
    @type = AlertType.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
