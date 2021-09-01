class EasySlaEventsController < ApplicationController

  menu_item :easy_sla_events

  # before_action :find_easy_sla_events, only: [:destroy]
  before_action :find_easy_sla_event, only: [:destroy]
  before_action :find_optional_project, only: [:destroy]
  before_action :authorize, only: [:destroy]
  before_action :authorize_global, only: [:index]

  # helper :context_menus
  include_query_helpers

  helper :custom_fields
  include CustomFieldsHelper

  accept_api_auth :destroy

  def index
    index_for_easy_query(EasySlaEventQuery)
  end

  def destroy
    # @easy_sla_events.each do |easy_sla_event|
    #   easy_sla_event.destroy
    # end
    @easy_sla_event.destroy
    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default issue_path(@easy_sla_event.issue_id)
      }
      format.api { render_api_ok }
    end
  end

  # def context_menu
  #   if @easy_sla_events.size == 1
  #     @easy_sla_event = @easy_sla_events.first
  #   end
  #
  #   can_edit = @easy_sla_events.detect{|c| !c.editable?}.nil?
  #   can_delete = @easy_sla_events.detect{|c| !c.deletable?}.nil?
  #   @can = {edit: can_edit, delete: can_delete}
  #   @back = back_url
  #
  #   @easy_sla_event_ids, @safe_attributes, @selected = [], [], {}
  #   @easy_sla_events.each do |e|
  #     @easy_sla_event_ids << e.id
  #     @safe_attributes.concat e.safe_attribute_names
  #     attributes = e.safe_attribute_names - (%w(custom_field_values custom_fields))
  #     attributes.each do |c|
  #       column_name = c.to_sym
  #       if @selected.key? column_name
  #         @selected[column_name] = nil if @selected[column_name] != e.send(column_name)
  #       else
  #         @selected[column_name] = e.send(column_name)
  #       end
  #     end
  #   end
  #
  #   @safe_attributes.uniq!
  #
  #   render layout: false
  # end


  private

  def find_easy_sla_event
    @easy_sla_event = EasySlaEvent.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # def find_easy_sla_events
  #   @easy_sla_events = EasySlaEvent.visible.where(id: (params[:id] || params[:ids])).to_a
  #   @easy_sla_event = @easy_sla_events.first if @easy_sla_events.count == 1
  #   raise ActiveRecord::RecordNotFound if @easy_sla_events.empty?
  #   raise Unauthorized unless @easy_sla_events.all?(&:visible?)
  #   @projects = @easy_sla_events.collect(&:project).compact.uniq
  #   @project = @projects.first if @projects.size == 1
  # rescue ActiveRecord::RecordNotFound
  #   render_404
  # end

end
