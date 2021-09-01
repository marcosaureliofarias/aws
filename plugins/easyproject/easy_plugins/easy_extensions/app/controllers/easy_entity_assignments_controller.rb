class EasyEntityAssignmentsController < ApplicationController

  before_action :find_project_by_project_id
  before_action :find_source_entity
  before_action :find_entity, :only => [:destroy]
  before_action :create_easy_query, :only => [:index, :update]
  before_action :create_options

  helper :sort
  include SortHelper
  helper :easy_query
  helper :custom_fields

  COLLECTION_LIMIT = 10

  def index
    sort_init(@easy_query.sort_criteria_init)
    sort_update(@easy_query.sortable_columns)
    #prepare_easy_query_render(@easy_query)
    render layout: !request.xhr?
  end

  def update
    sort_init(@easy_query.sort_criteria_init)
    sort_update(@easy_query.sortable_columns)
    @easy_query.set_as_default if User.current.admin?
    redirect_to action: :index, params: @easy_query.to_params.merge({ source_entity_type:         params[:source_entity_type],
                                                                      source_entity_id:           params[:source_entity_id],
                                                                      referenced_collection_name: params[:referenced_collection_name]
                                                                    })
  end

  def destroy
    relation = @source_entity.send(params[:referenced_collection_name])

    relation.delete(@entity)
    call_hook(:easy_entity_assignments_after_delete, entity: @entity, source_entity: @source_entity, relation_name: params[:referenced_collection_name])

    respond_to do |format|
      format.js
    end
  end

  private

  def find_source_entity
    begin
      @source_entity = params[:source_entity_type].constantize.find(params[:source_entity_id]) if params[:source_entity_type] && params[:source_entity_id]
    rescue
    end

    render_404 unless @source_entity
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_entity
    begin
      @entity = params[:referenced_entity_type].constantize.find(params[:referenced_entity_id]) if params[:referenced_entity_type] && params[:referenced_entity_id]
    rescue
    end

    render_404 unless @entity
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project_by_project_id
    @project = Project.find(params.delete(:project_id)) if params[:project_id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def create_easy_query
    @easy_query = EasyQuery.new_subclass_instance(params[:type]) if params[:type]
    return render_404 if @easy_query.nil?
    @easy_query.name = 'Assignment Query'
    @easy_query.user = User.current
    return render_404 if !@source_entity.respond_to?(params[:referenced_collection_name])
    @easy_query.source_entity = @source_entity
    @easy_query.render_context = 'entity_assignments'
    @easy_query.from_params(params)
    @easy_query.set_sort_params(sort: @easy_query.send(:get_default_values_from_easy_settings, EasyQuery::DEFAULT_SORTING_SUFFIX, render_context: nil))
    @show_load_all_button = @easy_query.entity_count > COLLECTION_LIMIT
    @easy_query.add_additional_scope(-> { limit(COLLECTION_LIMIT) })
    @easy_query.column_names = options[:query_column_names] unless params[:query_column_names].blank?
    @easy_query.group_by = nil
  end

  def create_options
    @options = {}
    # @options[:heading] ||= l("label_#{params[:referenced_entity_type].underscore}_plural", :default => 'Heading')
    @options[:module_name]                ||= params[:module_name]
    @options[:referenced_collection_name] ||= params[:referenced_collection_name]
    @options[:module_name]                ||= "entity_#{@source_entity.class.name.to_id}_#{@source_entity.id}_#{@options[:referenced_collection_name].to_s}"
    @options[:hascontextmenu]             ||= true
    if params[:hide_remove_entity_link]
      @options[:hide_remove_entity_link] = params[:hide_remove_entity_link]
    elsif @source_entity.respond_to?(:editable?)
      @options[:hide_remove_entity_link] ||= !@source_entity.editable?
    end
  end

end
