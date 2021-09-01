class ModalSelectorsController < ApplicationController

  before_action :find_modal_project

  helper :custom_fields
  include CustomFieldsHelper
  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper
  # Don't use ModalSelectorsHelper elsewhere!
  helper :modal_selectors
  include ModalSelectorsHelper
  helper :projects
  include ProjectsHelper
  helper :issues
  include IssuesHelper

  def index
    action = params[:entity_action].to_s.to_sym
    if self.respond_to?(action)
      __send__(action)
    else
      render_404
    end
  end

  def issue
    retrieve_query(EasyIssueQuery)
    @query.name = (params[:query_name].blank? ? l('easy_query.easy_lookup.name.issue.default') : l("easy_query.easy_lookup.name.issue.#{params[:query_name]}"))

    if @modal_project && params[:parent_selection]
      @query.set_entity_scope(Issue.cross_project_scope(@modal_project, Setting.cross_project_subtasks).visible)
    end

    set_query(@query, params)

    sort_init(@query.sort_criteria_init)
    sort_update(@query.sortable_columns)

    prepare_easy_query_render

    if request.xhr? && !@entities
      render_404
      return false
    end

    if loading_group?
      render_easy_query_html(@query, nil, { :selected_values => prepare_selected_values })
    else
      render_modal_selector_entities_list(@query, @entities, @entity_pages, @entity_count)
    end
  end

  def project
    retrieve_query(EasyProjectQuery)
    @query.name = (params[:query_name].blank? ? l('easy_query.easy_lookup.name.project.default') : l("easy_query.easy_lookup.name.project.#{params[:query_name]}"))
    @query.dont_use_project = true
    set_query(@query)

    sort_init(@query.sort_criteria_init)
    sort_update(@query.sortable_columns)

    prepare_easy_query_render

    if request.xhr? && !@entities
      render_404
      return false
    end

    if loading_group?
      render_easy_query_html(@query, nil, { :selected_values => prepare_selected_values })
    else
      render_modal_selector_entities_list(@query, @entities, @entity_pages, @entity_count)
    end
  end

  def version
    retrieve_query(EasyVersionQuery)
    @query.name = (params[:query_name].blank? ? l('easy_query.easy_lookup.name.version.default') : l("easy_query.easy_lookup.name.version.#{params[:query_name]}"))

    set_query(@query)

    sort_init(@query.sort_criteria_init)
    sort_update(@query.sortable_columns)

    if params[:current_project_id].present?
      @query.current_project_id = Project.where(id: params[:current_project_id]).pluck(:id).first
    end

    prepare_easy_query_render

    if request.xhr? && !@entities
      render_404
      return false
    end

    if loading_group?
      render_easy_query_html(@query, nil, { :selected_values => prepare_selected_values })
    else
      render_modal_selector_entities_list(@query, @entities, @entity_pages, @entity_count)
    end
  end

  def user
    retrieve_query(EasyUserQuery)
    @query.name = (params[:query_name].blank? ? l('easy_query.easy_lookup.name.user.default') : l("easy_query.easy_lookup.name.user.#{params[:query_name]}"))

    set_query(@query)

    sort_init(@query.sort_criteria_init)
    sort_update(@query.sortable_columns)

    prepare_easy_query_render

    if request.xhr? && !@entities
      render_404
      return false
    end

    if loading_group?
      render_easy_query_html(@query, nil, { :selected_values => prepare_selected_values })
    else
      render_modal_selector_entities_list(@query, @entities, @entity_pages, @entity_count)
    end
  end

  def group
    retrieve_query(EasyGroupQuery)
    @query.name = (params[:query_name].blank? ? l('easy_query.easy_lookup.name.group.default') : l("easy_query.easy_lookup.name.group.#{params[:query_name]}"))

    set_query(@query)

    sort_init(@query.sort_criteria_init)
    sort_update(@query.sortable_columns)

    prepare_easy_query_render

    if request.xhr? && !@entities
      render_404
      return false
    end

    if loading_group?
      render_easy_query_html(@query, nil, { :selected_values => prepare_selected_values })
    else
      render_modal_selector_entities_list(@query, @entities, @entity_pages, @entity_count)
    end
  end

  def document
    retrieve_query(EasyDocumentQuery)
    @query.name                             = (params[:query_name].blank? ? l('easy_query.easy_lookup.name.document.default') : l("easy_query.easy_lookup.name.document.#{params[:query_name]}"))
    @query.display_filter_columns_on_index  = true
    @query.display_filter_group_by_on_index = true
    @query.display_filter_sort_on_index     = false

    set_query(@query)

    sort_init(@query.sort_criteria_init)
    sort_update(@query.sortable_columns)

    prepare_easy_query_render

    if request.xhr? && !@entities
      render_404
      return false
    end

    if loading_group?
      render_easy_query_html(@query, nil, { :selected_values => prepare_selected_values })
    else
      render_modal_selector_entities_list(@query, @entities, @entity_pages, @entity_count)
    end
  end

  def search
    @easy_query = EasyQuery.new_subclass_instance(params[:type]) if params[:type]
    return render_404 if @easy_query.nil?

    @easy_query.name                             = params[:translated_query_name] || '_'
    @easy_query.display_filter_columns_on_index  = false
    @easy_query.display_filter_group_by_on_index = false
    @easy_query.display_filter_sort_on_index     = false

    set_query(@easy_query)
    @easy_query.project = nil

    sort_init(@easy_query.sort_criteria_init)
    sort_update(@easy_query.sortable_columns)

    @question = params[:easy_query_q] || ''
    @question.strip!

    hook_context = { :easy_query => @easy_query, :question => @question, :project => @modal_project }
    call_hook(:controller_modal_selecotrs_action_search_before_search, hook_context)
    @question   = hook_context[:question]
    @easy_query = hook_context[:easy_query]

    if @question.match(/^#?(\d+)$/)
      @easy_query.entity_scope    = @easy_query.entity_scope.where(:id => $1)
      @easy_query.use_free_search = false
      @easy_query.filters         = {}
      begin
        entity       = @easy_query.entities
        entity_count = entity.size
      rescue RangeError
        entity, entity_count = [], 0
      end
      entity_pages = Redmine::Pagination::Paginator.new(entity_count, per_page_option, params[:page])
      return render_modal_selector_entities_list(@easy_query, entity, entity_pages, entity_count)
    end

    # extract tokens from the question
    # eg. hello "bye bye" => ["hello", "bye bye"]
    @tokens = @question.scan(%r{((\s|^)"[\s\w]+"(\s|$)|\S+)}).collect { |m| m.first.gsub(%r{(^\s*"\s*|\s*"\s*$)}, '') }
    # tokens must be at least 2 characters long
    @tokens      = @tokens.uniq.select { |w| w.length > 1 }
    entity_count = @easy_query.search_freetext_count(@tokens)
    entity_pages = Redmine::Pagination::Paginator.new entity_count, 25, params['page']

    if entity_pages.last_page.to_i < params['page'].to_i
      render_404
      return false
    end

    if !@tokens.empty? && entity_count > 0
      # no more than 5 tokens to search for
      @tokens.slice! 5..-1 if @tokens.size > 5
      @entities = @easy_query.search_freetext(@tokens)
    elsif @question.blank?
      @entities = @easy_query.entities(:offset => entity_pages.offset, :order => sort_clause)
    end

    render_modal_selector_entities_list(@easy_query, @entities || [], entity_pages, entity_count)
  end

  #kind of hack for call function 'format_html_entity_attribute'
  def link_to(*args, &block)
    view_context.link_to(*args, &block).html_safe
  end

  def mail_to(email_address, name = nil, html_options = {})
    view_context.mail_to(email_address, name, html_options)
  end

  private

  def find_modal_project
    @modal_project = Project.find(params[:modal_project_id]) unless params[:modal_project_id].blank?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def render_modal_selector(query, entities, entity_pages, entity_count, selected_values = nil, easy_query_renderer_method = :render_modal_selector_easy_query_list, options = {})
    options[:button_selector_assign_label] ||= l(:button_easy_lookup_modal_selector_assign)
    options[:button_selector_assign_title] ||= l(:title_easy_lookup_modal_selector_assign)
    options[:button_close_label]           ||= l(:button_easy_lookup_modal_close)
    options[:button_close_title]           ||= l(:title_close)
    options[:multiple]                     = params[:multiple]
    options[:multiple]                     ||= '1'
    raise ArgumentError, 'Option selectable_entities has to be a Hash! {entity_name => field_name}' if options[:selectable_entities] && !options[:selectable_entities].is_a?(Hash)
    options[:selectable_entities] ||= {}

    render :partial => 'modal_selectors/modal_selector', :locals => { :query => query, :entities => entities, :entity_pages => entity_pages, :entity_count => entity_count, :selected_values => selected_values, :easy_query_renderer_method => easy_query_renderer_method, :options => options }
  end

  def find_nested_field_name(param, field_names)
    ret_value = param
    field_names.each do |curr_key|
      ret_value = ret_value.first if ret_value.is_a?(Array)
      if ret_value.respond_to?(:key?) && ret_value.key?(curr_key)
        ret_value = ret_value[curr_key]
      else
        ret_value = nil
        break
      end
    end
    ret_value
  end

  def prepare_selected_values
    field_names = params['field_name'] && params['field_name'].gsub(/[\[\]]/, ',').split(',').select { |x| !x.blank? }
    ids         = find_nested_field_name(params, field_names) || params['selected_values'] if field_names


    return {} if ids.blank?
    ids = Array(ids)
    params.delete(field_names.first)

    if field_names.include?('custom_field_values')
      cf_id                  = field_names.last
      settings               = CustomField.find(cf_id).settings
      entity_class           = begin
        ; settings['entity_type'].constantize rescue nil;
      end
      entity_attribute       = settings['entity_attribute']
      entity_custom_field_id = settings['entity_custom_field']
    else
      entity_class           = begin
        ; params[:entity_action].classify.constantize rescue nil;
      end
      entity_attribute       = params['entity_attribute']
      entity_custom_field_id = params['entity_custom_field']
    end

    if entity_class.nil? && params[:type] && params[:entity_action] == 'search'
      query_type_class = begin
        ; params[:type].classify.constantize rescue nil;
      end
      entity_class     = begin
        ; query_type_class.new.entity rescue nil;
      end
    end

    if entity_attribute.start_with?('link_with_')
      attribute = EasyEntityAttribute.new(entity_attribute.sub('link_with_', ''))
    elsif entity_attribute == 'name_and_cf'
      cf        = CustomField.find_by_id(entity_custom_field_id)
      attribute = EasyEntityNamedCustomAttribute.new(entity_attribute, cf)
    else
      attribute = EasyEntityAttribute.new(entity_attribute, { :no_link => true })
    end

    selected_values = {}
    if entity_class && ids.any?
      entities = entity_class.where(:id => ids).to_a
      ids.each do |id|
        next unless entity = entities.detect { |e| e.id == id.to_i }
        options = { :entity => entity, :custom_field => cf }

        selected_values[id] = (view_context.format_html_entity_attribute(entity_class, entity_attribute, attribute.value(entity), options)).to_s.html_safe
      end

    end

    selected_values
  end

  def render_modal_selector_entities_list(query, entities, entity_pages, entity_count, options = {})
    selected_values = prepare_selected_values

    render_modal_selector(query, entities, entity_pages, entity_count, selected_values, :render_modal_selector_easy_query_entities_list, options)
  end

  def render_modal_selector_list(query, entities, entity_pages, entity_count, options = {})
    selected_values = prepare_selected_values

    render_modal_selector(query, entities, entity_pages, entity_count, selected_values, :render_modal_selector_easy_query_list, options)
  end

  def set_query(query, query_params = nil, options = {})
    query_params ||= params.dup
    query.from_params(query_params)

    if query_params[:modal_project_id] && !options[:skip_project_filter] && !query.dont_use_project.to_boolean
      if query.available_filters.key?('xproject_id')
        query.add_short_filter('xproject_id', '=' + query_params[:modal_project_id])
      elsif query.available_filters.key?('project_id')
        query.add_short_filter('project_id', '=' + query_params[:modal_project_id])
      end
    end
    query.export_formats = {}
  end

end
