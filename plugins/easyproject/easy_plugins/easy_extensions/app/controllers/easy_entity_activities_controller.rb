class EasyEntityActivitiesController < ApplicationController

  include_query_helpers
  helper :custom_fields

  before_action :require_login

  before_action :find_easy_entity_activity, only: [:edit, :destroy, :show, :update]

  accept_api_auth :create, :update, :destroy, :show, :index

  def index
    index_for_easy_query EasyEntityActivityQuery, [['start_time', 'desc']]
  end

  def show
    respond_to do |format|
      format.api
    end
  end

  def create
    @easy_entity_activity = EasyEntityActivity.new
    build_from_params #if request.format.js?
    @easy_entity_activity.safe_attributes = params[:easy_entity_activity]
    respond_to do |format|
      if @easy_entity_activity.save
        build_new_easy_entity_activity

        format.js
        format.api { render action: :show }
        # format.api { render_api_ok }
      else
        format.js { render_error :status => 422, :message => @easy_entity_activity.errors.full_messages.join(', ') }
        format.api { render_validation_errors(@easy_entity_activity) }
      end
    end
  end

  def edit
    @easy_entity_activity = @easy_entity_activity.to_decorate
    respond_to do |format|
      format.js
    end
  end

  def update
    build_from_params if params[:easy_entity_activity_attendees] # && request.format.js?
    @easy_entity_activity.safe_attributes = params[:easy_entity_activity]
    respond_to do |format|
      if @easy_entity_activity.save
        build_new_easy_entity_activity

        format.js
        format.api { render action: :show }
        # format.api { render_api_ok }
      else
        format.js { render_error :status => 422, :message => @easy_entity_activity.errors.full_messages.join(', ') }
        format.api { render_validation_errors(@easy_entity_activity) }
      end
    end
  end

  def destroy
    @easy_entity_activity.destroy

    respond_to do |format|
      format.js
      format.api { render_api_ok }
    end
  end

  private

  def build_from_params
    attendees = params[:easy_entity_activity_attendees]
    @easy_entity_activity.easy_entity_activity_attendees.clear
    attendees.each do |entity_name, ids|
      entity_class = (
      begin
        ; entity_name.constantize;
      rescue;
        nil;
      end)
      if entity_class && entity_class < ActiveRecord::Base
        entity_class.where(id: ids).each do |entity|
          @easy_entity_activity.easy_entity_activity_attendees.build(entity: entity)
        end
      end
    end if attendees
  end

  def find_easy_entity_activity
    @easy_entity_activity = EasyEntityActivity.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def build_new_easy_entity_activity
    @new_easy_entity_activity = EasyEntityActivity.new
    @new_easy_entity_activity = @new_easy_entity_activity.to_decorate do |object|
      @new_easy_entity_activity.author_id = @easy_entity_activity.author_id
      @new_easy_entity_activity.entity    = @easy_entity_activity.entity
    end
  end
end