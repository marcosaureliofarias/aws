class AlertContextsController < ApplicationController

  before_action :find_type, :only => [:show, :edit, :update, :destroy]
  before_action :authorize_global

  # GET /alert_types
  def index
    @contexts = AlertContext.all
  end

  # GET /alert_context/:id
  # GET /alert_context/:id/show
  def show
  end

  # GET /alert_context/new
  def new
    @context = AlertContext.new
  end

  # POST /alert_context
  def create
    @context = AlertContext.new(params.require(:alert_context).permit!)

    respond_to do |format|
      if @context.save
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_to( :action => 'index' ) }
      else
        format.html { render :action => "new" }
      end
    end

  end

  # GET /alert_context/:id/edit
  def edit
  end

  # PUT /alert_context/:id
  def update
    respond_to do |format|
      if @context.update_attributes(params.require(:alert_context).permit!)
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_to( :action => 'index' ) }
        format.api { render_api_ok }
      else
        format.html { render :action => 'edit' }
        format.api { render_validation_errors(@context) }
      end
    end
  end

  # DELETE /alert_context/:id
  def destroy
    @context.destroy

    respond_to do |format|
      flash[:notice] = l(:notice_successful_delete)
      format.html { redirect_to( :action => 'index' ) }
    end
  end


private

  def find_type
    @context = AlertContext.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
