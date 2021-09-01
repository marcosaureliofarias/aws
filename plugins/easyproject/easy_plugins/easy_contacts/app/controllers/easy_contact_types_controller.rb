class EasyContactTypesController < ApplicationController

  before_action :authorize_global
  before_action :find_type, only: [:show, :edit, :update, :destroy, :move_easy_contacts]

  accept_api_auth :index, :show, :create, :update, :destroy

  def index
    @types = EasyContactType.sorted
    respond_to do |format|
      format.html
      format.api
    end
  end

  def show
    respond_to do |format|
      format.api
    end
  end

  def new
    @type = EasyContactType.new
  end

  def create
    @type = EasyContactType.new
    @type.safe_attributes = params[:easy_contact_type]

    respond_to do |format|
      if @type.save
        flash[:notice] = l(:notice_successful_create)
        format.html { params[:back_url].blank? ? redirect_to( :action => 'index' ) : redirect_to(params[:back_url]) }
        format.api { render action: 'show' }
      else
        format.html { render :action => 'new' }
        format.api { render_validation_errors(@type) }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      @type.safe_attributes = params[:easy_contact_type]
      if @type.save
        flash[:notice] = l(:notice_successful_update)
        format.html { params[:back_url].blank? ? redirect_to( :action => 'index' ) : redirect_to(params[:back_url]) }
        format.api { render_api_ok }
      else
        format.html { render :action => "edit" }
        format.api { render_validation_errors(@type) }
      end
    end
  end

  def destroy
    respond_to do |format|
      unless @type.contacts.empty?
        format.html {
          flash[:error] = l(:error_can_not_delete_easy_contact_type)
          if EasyContactType.count > 1
            redirect_to move_easy_contacts_easy_contact_type_path(@type)
          else
            redirect_to action: 'index'
          end
        }
        format.api { render_api_head(422) }
      else
        @type.destroy
        format.html {
          flash[:notice] = l(:notice_successful_delete)
          redirect_back_or_default(:index)
        }
        format.api { render_api_ok }
      end
    end
  end

  def move_easy_contacts
    @other_types = EasyContactType.where.not(id: @type.id)
    easy_contact_type_to_id = params[:easy_contact_type_to_id]

    if request.post? && easy_contact_type_to_id.present? && easy_contact_type_to_id != @type.id.to_s
      @type_to = EasyContactType.find(easy_contact_type_to_id)

      map = params[:custom_fields_map]
      @type.move_easy_contacts(@type_to, map&.to_unsafe_h)
      @type.reload

      if @type.contacts.any?
        flash[:notice] = l(:notice_successful_delete)
      else
        @type.destroy
        redirect_to action: 'index'
      end
    end
  end

  def custom_field_mapping
    begin
      @type = EasyContactType.includes(:custom_fields).find(params[:id])
      @type_to = EasyContactType.includes(:custom_fields).find(params[:easy_contact_type_to_id])
    rescue ActiveRecord::RecordNotFound
      render_404
      return
    end

    @custom_field_data = @type.custom_field_mapping_data(@type_to)
    render layout: false
  end

  private

    def find_type
      @type = EasyContactType.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end

end
