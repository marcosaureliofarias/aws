class EasyDefaultQueryMappingsController < ApplicationController

  before_action { |c| c.require_admin_or_lesser_admin(:easy_query_settings) }

  before_action :find_easy_query_type, only: [:new, :create]
  before_action :find_easy_query_mapping, only: [:edit, :destroy, :update]

  accept_api_auth :destroy, :create, :update

  def new
    @easy_query_mapping             = EasyDefaultQueryMapping.new
    @easy_query_mapping.entity_type = @easy_query_type.name

    respond_to do |format|
      format.html
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def create
    @easy_query_mapping                 = EasyDefaultQueryMapping.new
    @easy_query_mapping.safe_attributes = params[:easy_default_query_mapping]
    @easy_query_mapping.entity_type     = @easy_query_type.name
    respond_to do |format|
      if @easy_query_mapping.save
        format.html {
          redirect_to edit_easy_query_management_path(type: @easy_query_type), notice: l(:notice_successful_update)
        }
        format.api { render_api_ok }
      else
        format.html { render action: :edit }
        format.api { render_validation_errors(@easy_query_mapping) }
      end
    end
  end

  def update
    @easy_query_mapping.safe_attributes = params[:easy_default_query_mapping]
    respond_to do |format|
      if @easy_query_mapping.save
        format.js { head :ok }
        format.html {
          redirect_to edit_easy_query_management_path(type: @easy_query_type), notice: l(:notice_successful_update)
        }
        format.api { render_api_ok }
      else
        format.js { head :ok }
        format.html { render action: :edit }
        format.api { render_validation_errors(@easy_query_mapping) }
      end
    end
  end

  def destroy
    @easy_query_mapping.destroy
    respond_to do |format|
      format.html {
        redirect_to edit_easy_query_management_path(type: @easy_query_type), notice: l(:notice_successful_update)
      }
      format.js
      format.api { render_api_ok }
    end
  end

  def find_easy_query_type
    subclasses = EasyQuery.registered_subclasses
    type       = if subclasses.has_key?(params[:type])
                   params[:type]
                 elsif params[:easy_default_query_mapping].present? && subclasses.has_key?(params[:easy_default_query_mapping][:entity_type])
                   params[:easy_default_query_mapping][:entity_type]
                 end

    @easy_query_type = EasyQuery.get_subclass(type)
    render_404 unless @easy_query_type
  end

  def find_easy_query_mapping
    @easy_query_mapping = EasyDefaultQueryMapping.find(params[:id])
    @easy_query_type    = EasyQuery.get_subclass(@easy_query_mapping.entity_type)
    render_404 unless @easy_query_type
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
