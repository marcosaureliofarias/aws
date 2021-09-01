class EasyQueriesController < ApplicationController

  before_action :create_query, :only => [:new, :create]
  before_action :find_query, :only => [:edit, :update, :destroy, :load_users_for_copy, :copy_to_users, :show]
  before_action :find_optional_project, :only => [:show, :modal_for_trend]
  before_action :try_find_optional_project, :only => [:new, :create, :update]
  before_action :find_optional_project_no_auth, :only => [:entities, :filters, :filter_values, :output_data, :chart, :calendar]
  before_action :check_editable, :authorize_global, :only => [:create, :edit, :update, :new, :destroy]
  before_action :find_easy_page_zone_module_and_easy_query, :only => [:entities, :output_data, :chart, :calendar]
  before_action :update_query, :only => [:update]
  before_action :from_params, :only => [:new, :create, :update]

  layout :has_layout

  accept_api_auth :index
  include_query_helpers

  def index
    case params[:format]
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end
    @easy_queries = EasyQuery.visible
    @easy_queries = @easy_queries.where(type: params[:type]) if params[:type].present?
    @query_count  = @easy_queries.count
    @query_pages  = Paginator.new @query_count, @limit, params['page']
    @easy_queries = @easy_queries.
        order("#{EasyQuery.table_name}.name").
        limit(@limit).
        offset(@offset).
        to_a
    @easy_queries.reject! { |easy_query| easy_query.is_a?(EasyQuery.disabled_sti_class) }

    respond_to do |format|
      format.api
    end
  end

  def show
    path = @easy_query.entity_easy_query_path(:project => @project, :query_id => @easy_query)
    path ? redirect_to(path) : render_404
  end

  def new
    # before_action :create_query
    render :layout => false if request.xhr?
  end

  def create
    if params[:confirm] && @easy_query.save
      flash[:notice] = l(:notice_successful_create)

      if params[:back_url].present? && (valid_url = validate_back_url(params[:back_url]))
        separator = valid_url.include?('?') ? '&' : '?'
        redirect_to "#{valid_url}#{separator}query_id=#{@easy_query.id}"
      else
        if !@easy_query.is_for_all? && @easy_query.entity <= Project
          redirect_to @easy_query.entity_easy_query_path(project: @project)
        else
          redirect_to @easy_query.entity_easy_query_path(project: @project, query_id: @easy_query)
        end
      end
      return
    else
      render :action => 'new'
    end
  end

  def edit
    # before_action :find_query
  end

  def update
    # before_action :find_query, :update_query, :from_params
    if @easy_query.save
      flash[:notice] = l(:notice_successful_update)
      default_path   = if !@easy_query.is_for_all? && @easy_query.entity <= Project
                         @easy_query.entity_easy_query_path(project: @project) || ''
                       else
                         @easy_query.entity_easy_query_path(project: @project, query_id: @easy_query) || ''
                       end
      @project ? redirect_to(default_path) : redirect_back_or_default(default_path)
    else
      render action: 'edit'
    end
  end

  def destroy
    @easy_query.destroy
    # sort_clear for this query
    session["#{@easy_query.easy_query_entity_controller}_#{@easy_query.easy_query_entity_action}_sort"] = nil
    [params[:back_url], params[:back_url2]].compact.each { |url| url.to_s.gsub!(/query_id=\d+&?/, '') }

    respond_to do |format|
      format.html { redirect_back_or_default(@easy_query.entity_easy_query_path(project: @project)) }
      format.api { render_api_head :no_content }
    end
  end

  def preview
    @query = EasyQuery.new_subclass_instance(params[:easy_query_type], name: '_') unless params[:easy_query_type].blank?

    if @query
      sort_init(@query.sort_criteria_init)
      sort_update(@query.sortable_columns)
      unless params[:block_name].blank?
        received_params            = params.to_unsafe_hash.dup
        query_params               = received_params.delete(params[:block_name]) || {}
        query_params['set_filter'] = '1'
        @query.from_params(received_params.merge(query_params))
        @query.project_id = params[:project_id] if params[:project_id].present?
      end

      add_additional_statement_to_query(@query)

      row_limit = (params[params[:block_name]] && params[params[:block_name]][:row_limit]) ? params[params[:block_name]][:row_limit].to_i : 10
      options   = { limit: (row_limit > 0 ? row_limit : nil), order: @query.sort_criteria_to_sql_order }
      prepare_easy_query_render(@query, options)

      case params[:easy_query_render]
      when 'table'
        render_easy_query(@query)
        return
      when 'tree'
        render partial: 'easy_queries/easy_query_entities_tree', locals: { query: @query, entities: @entities, block_name: params[:block_name] }
        return
      end
    end

    head :ok
  end

  def modal_for_trend
    query_klass = EasyQuery.get_subclass(params[:type])

    if query_klass.nil?
      return render_404
    end

    params[:modal] = '1'

    retrieve_query(query_klass)
    @query.name   = l('easy_pages.modules.trends')
    @query.output = 'list'
    @query.display_as_tree_with_expander_on_root = false

    if params['set_default_columns'] == '1'
      @query.column_names = @query.default_list_columns.map(&:to_s) | @query.column_names.map(&:to_s)
    end

    sort_init(@query.sort_criteria.presence || @query.default_sort_criteria.presence || [])
    sort_update(@query.sortable_columns)

    prepare_easy_query_render(@query)
    render_easy_query(@query)
  end

  def easy_document_preview
    query = params[:easy_query_type].constantize.new(:name => '_') unless params[:easy_query_type].blank?

    if query
      sort_init(query.sort_criteria_init)
      sort_update(query.sortable_columns)
      query.from_params(params[params[:block_name]]) unless params[:block_name].blank?
      documents = query.entities(:include => [:project, :category, :attachments])

      if params[:block_name]
        row_limit = params[params[:block_name]][:row_limit].to_i
        sort_by   = params[params[:block_name]][:sort_by]
      end
      documents_count, documents = EasyDocumentQuery.filter_non_restricted_documents(documents, User.current, row_limit || 0, sort_by || '')

      render :partial => 'documents/index', :locals => { :grouped => documents }
    else
      head :ok
    end

  end

  def entities
    @entities = @easy_query.entities

    respond_to do |format|
      format.json
    end
  end

  def filters(partial = 'filters')
    add_easy_page_zone_module_data(params[:easy_page_zone_module_uuid])

    query_klass = EasyQuery.get_subclass(params[:type]) if params[:type]
    return render_404 if query_klass.nil?
    retrieve_query(query_klass, false, { :query_param => params[:query_param], :skip_project_cond => true, :dont_use_project => params[:dont_use_project] })

    render_with_fallback :partial => partial, :prefixes => @query, :locals => {
        :query         => @query,
        :modul_uniq_id => params[:modul_uniq_id],
        :block_name    => params[:block_name]
    }
  end

  def filters_custom_formatting
    filters('filters_custom_formatting')
  end

  def filter_values
    @filter = params[:filter_name]
    render_404 and return if @filter.blank?

    add_easy_page_zone_module_data(params[:easy_page_zone_module_uuid])

    modal_selector = params[:modul_uniq_id] == 'modal_selector'
    query_params = {
        query_param: params[:query_param],
        skip_project_cond: true,
        dont_use_project: params[:dont_use_project],
        modal_selector: modal_selector
    }
    query_klass = EasyQuery.get_subclass(params[:type])
    return render_404 unless query_klass

    retrieve_query(query_klass, false, query_params)

    if @filter.is_a?(Array)
      @values = {}
      @filter.each do |filter|
        next unless @query.available_filters.has_key?(filter)
        @values[filter] = @query.available_filters[filter][:values]
        @values[filter] = @values[filter].call if @values[filter].is_a?(Proc)
        if (params[:filters_type] && params[:filters_type] == 'attr_writer')
          Redmine::Hook.call_hook(:easy_query_writer_filters, query: @query, filter: filter, values: @values[filter])
        end
      end
    else
      if @query.available_filters.has_key?(@filter)
        @values = @query.available_filters[@filter][:values]
        @values = @values.call if @values.is_a?(Proc)
        if (params[:filters_type] && params[:filters_type] == 'attr_writer')
          Redmine::Hook.call_hook(:easy_query_writer_filters, query: @query, filter: @filter, values: @values)
        end
      end
      @values ||= []
    end

    respond_to do |format|
      format.html { render layout: false }
      format.json { render json: @values }
    end
  end

  # def load_group
  #   retrieve_query(params[:easy_query_type].constantize)
  #
  #   entities = @query.entities_for_group(loading_group)
  #   render :partial => 'easy_queries/easy_query_entities', :locals => { query: @query, entities: entities, options: (params[:view_options] || {}) }
  # end

  def output_data
    @easy_query.output = params[:output]

    respond_to do |format|
      format.api
    end
  end

  def chart
    @chart_settings    = @easy_query.chart_settings
    @easy_query.output = 'chart'

    respond_to do |format|
      format.json
    end
  end

  def calendar
    respond_to do |format|
      format.html { render partial: 'easy_query_calendar', locals: { calendar: @calendar, easy_query: @easy_query } }
    end
  end

  def find_by_easy_query
    @modal_title = params[:title] if params[:title].present?
    if params[:type].present?
      @type = params[:type].constantize
      respond_to do |format|
        format.js
      end
    else
      render_404
    end
  rescue NameError
    render_404
  end

  def load_users_for_copy
    @users_having_query = @easy_query.query_copies.preload(:user).inject({}) do |users, query_copy|
      users[query_copy.user_id] = query_copy.user.name if query_copy.user&.visible?
      users
    end

    respond_to do |format|
      format.js
    end
  end

  def copy_to_users
    not_copied_user = []
    User.where(:id => params[:users]).each do |user|
      if (copied_easy_query = @easy_query.copy(:user_id => user.id))
        EasyMailer.easy_query_copied_notify(user, copied_easy_query).deliver
        flash[:notice] = l(:notice_query_copied)
      else
        not_copied_user << user.name
      end
      flash[:error] = l(:error_query_copy_incomplete, :user_name => not_copied_user.join(', ')) if not_copied_user.any?
    end
    redirect_back_or_default(easy_query_path(@easy_query))
  end

  private

  def create_query
    @easy_query = EasyQuery.new_subclass_instance(params[:type]) if params[:type]
    return render_404 if @easy_query.nil?
    @easy_query.attributes = params[:easy_query].permit! if params[:easy_query]
    @easy_query.user       = User.current
  end

  def update_query
    @easy_query.attributes = params[:easy_query].permit! if params[:easy_query]
  end

  def from_params
    @easy_query.project            = @project
    @easy_query.is_for_subprojects = params[:is_for_subprojects]
    @easy_query.from_params(params)
    @easy_query.visibility   = EasyQuery::VISIBILITY_PRIVATE unless User.current.allowed_to?(:manage_public_queries, @project, :global => true) || User.current.admin?
    @easy_query.column_names = nil if params[:default_columns]

    if params['daily_snapshot'] == '1' && (eqs_attrs = params.delete('easy_query_snapshot'))
      @easy_query.easy_query_snapshot_attributes = eqs_attrs.to_unsafe_h.merge('author_id' => User.current.id)
    elsif params['daily_snapshot'] == '0'
      @easy_query.easy_query_snapshot.mark_for_destruction if @easy_query.easy_query_snapshot
    end
  end

  def find_query
    @easy_query = EasyQuery.find_by(:id => params[:id]) || EasyQuery.find_by(:id => params[:easy_query_id])
    if @easy_query.nil?
      return render_404
    elsif !@easy_query.visible?
      return render_403
    end
    @easy_query.user ||= User.current
  end

  def check_editable
    render_403 unless @easy_query.editable_by?(User.current)
  end

  def find_optional_project(auth = true)
    render_404 if params[:project_id] && !try_find_optional_project
  end

  # When query is saved URL can have format: project_id=1|2|3
  # => result will be render_404
  def try_find_optional_project
    @project = Project.find(params[:project_id]) if params[:project_id] && !params[:query_is_for_all]
  rescue ActiveRecord::RecordNotFound
    @project = @easy_query.try(:project)
  end

  def find_optional_project_no_auth
    find_optional_project(false)
  end

  def find_easy_page_zone_module_and_easy_query
    if !params[:uuid].blank? && (@easy_page_zone_module = EasyPageZoneModule.find(params[:uuid]))
      module_params            = params[:block_name].blank? ? params : params[params[:block_name]]
      module_params['outputs'] = ['chart'] if module_params['chart'].present?
      ret_val                  = @easy_page_zone_module.get_show_data(User.current, module_params, { project: @project })

      @easy_query = ret_val[:query]
      @calendar   = ret_val[:calendar]
      @entities   = ret_val[:entities]
    else
      query_klass = if params[:easy_query_type].present?
        EasyQuery.get_subclass(params[:easy_query_type])
      elsif params[:type].present?
        EasyQuery.get_subclass(params[:type])
      end
      return render_404 unless query_klass

      if params[:id]
        @easy_query                  = query_klass.find(params[:id])
        @easy_query.dont_use_project = params[:dont_use_project]
        @easy_query.project          = @easy_query.dont_use_project ? nil : @project
        @easy_query.set_additional_params(params)
      else
        @easy_query                  = query_klass.new
        @easy_query.dont_use_project = params[:dont_use_project]
        @easy_query.project          = @easy_query.dont_use_project ? nil : @project
        @easy_query.name             = params[:query_name] unless params[:query_name].blank?
        @easy_query.from_params(params[:block_name].blank? ? params : params[params[:block_name]])
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def add_additional_statement_to_query(query)
    if query.is_a?(EasyProjectQuery)
      additional_statement = "#{Project.table_name}.easy_is_easy_template=#{query.class.connection.quoted_false}"
      additional_statement << (' AND ' + Project.visible_condition(User.current))

      if query.additional_statement.blank?
        query.additional_statement = additional_statement
      else
        query.additional_statement << ' AND ' + additional_statement
      end
    end
  end

  def has_layout
    action_name == 'modal_for_trend' ? false : nil
  end

end
