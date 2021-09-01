module EasyQueryHelper
  include Redmine::Export::PDF

  def self.included(klass)
    # When this helper use over `helper :EasyQuery`
    # but it does not pass through `include EasyQuery` v controlleru
    # When addition Easy QueryHelper adds even EasyQuery Buttons Helper if not for controller
    if klass < ApplicationHelper && !(klass < ApplicationController)
      klass.include(EasyQueryButtonsHelper)
    end
  end

  # -----------------------------------------
  # retrieve query for entity - EasyIssueQuery, EasyUserQuery ...
  def retrieve_query(entity_query, use_session = false, options = {})
    entity_session = entity_query.name.underscore

    if !params[:query_id].blank?
      cond = ''
      unless options[:skip_project_cond] # Filter belongs to project and is using without project
        cond << 'project_id IS NULL'
        if @project
          cond << " OR project_id = #{@project.id}"
          cond << " OR (is_for_subprojects = #{@project.class.connection.quoted_true} AND project_id IN (#{@project.ancestors.select("#{Project.table_name}.id").to_sql}))" unless @project.root?
        end
      end

      @query = entity_query.where(cond).find_by(:id => params[:query_id])
      raise ActiveRecord::RecordNotFound if @query.nil?
      raise ::Unauthorized unless @query.visible?
      @query.set_additional_params(options[:query_param] ? params[options[:query_param]] : params)
      @query.dont_use_project = options[:dont_use_project]
      @query.project          = @query.dont_use_project ? nil : @project
      session[entity_session] = { :id => @query.id, :project_id => @query.project_id }
      sort_clear if respond_to?(:sort_clear)
    elsif params[:set_filter] || session[entity_session].nil? || entity_session_project_id_changed?(entity_query)
      # Give it a name, required to be valid
      @query         = entity_query.new(:name => '_', :dont_use_project => options[:dont_use_project])
      @query.project = @query.dont_use_project ? nil : @project
      @query.from_params(options[:query_param] ? params[options[:query_param]] : params)
      if params[:set_filter] == '0'
        session[entity_session] = nil
        sort_clear if respond_to?(:sort_clear)
      elsif options[:use_session_store]
        session[entity_session] = { :project_id => @query.project_id, :filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names, :show_sum_row => @query.show_sum_row?, :load_groups_opened => @query.load_groups_opened?, period_start_date: @query.period_start_date, period_end_date: @query.period_end_date, period_date_period: @query.period_date_period, period_date_period_type: @query.period_date_period_type, :show_avatars => @query.show_avatars? }
      end
    else
      @query = nil
      if api_request? && params[:force_use_from_session].blank?
        @query         = entity_query.new(:name => '_', :dont_use_project => options[:dont_use_project])
        @query.project = @query.dont_use_project ? nil : @project
      else
        @query = entity_query.find(session[entity_session][:id]) if session[entity_session][:id] &&
            entity_query.exists?(session[entity_session][:id])

        @query ||= entity_query.new(name: '_',
                                    group_by: session[entity_session][:group_by],
                                    show_sum_row: session[entity_session][:show_sum_row],
                                    load_groups_opened: session[entity_session][:load_groups_opened],
                                    column_names: session[entity_session][:column_names],
                                    project: @project,
                                    period_start_date: session[entity_session][:period_start_date],
                                    period_end_date: session[entity_session][:period_end_date],
                                    period_date_period: session[entity_session][:period_date_period],
                                    period_date_period_type: session[entity_session][:period_date_period_type],
                                    show_avatars: session[entity_session][:show_avatars])

        @query.dont_use_project = options[:dont_use_project]
        @query.project          = @query.dont_use_project ? nil : @project
      end

      if @query.new_record?
        if session[entity_session][:filters]
          @query.filters = session[entity_session][:filters] if session[entity_session][:filters]
        else
          @query.filters = @query.default_filter
        end
      end
    end

    @query.custom_formatting = @query.default_custom_formatting if @query.custom_formatting.blank? && EasySetting.value('show_easy_custom_formatting')

    #prechodne TODO: delete it!
    @query.loading_group = loading_group
    @query
  end

  def easy_query_to_presenter(easy_query, options = {})
    container_id    ||= easy_query.entity.name.pluralize.underscore
    default_options = { entities:        @entities,
                        entity_pages:    @entity_pages,
                        entity_count:    @entity_count,
                        easy_query_name: easy_query.new_record? ? easy_query.default_name : easy_query.name,
                        block_name:      'easy_query',
                        container_id:    container_id,
                        modul_uniq_id:   container_id,
                        groups_url:      { params: request.parameters.except('group_to_load') },
                        form_options:    {},
                        options:         { hascontextmenu: true }
    }
    options         = default_options.deep_merge(options.except(:query, :easy_query))

    present(easy_query, options)
  end

  def entity_session_project_id_changed?(entity_query)
    entity_session = entity_query.name.underscore
    session[entity_session][:project_id] != @project.try(:id)
  end

  def retrieve_query_from_session(entity_query)
    entity_session = entity_query.name.underscore
    if session[entity_session]
      if session[entity_session][:id]
        @query = entity_query.find_by_id(session[entity_session][:id])
        return unless @query
      else
        @query = entity_query.new(:name => "_", :filters => session[entity_session][:filters], :group_by => session[entity_session][:group_by], :column_names => session[entity_session][:column_names])
      end
      if session[entity_session].has_key?(:project_id)
        @query.project_id = session[entity_session][:project_id]
      else
        @query.project = @project
      end
      @query
    end
  end

  def easy_query_group_entities_list(entities, query = nil, options = {}, &block)
    if entities.is_a?(Array)
      if query && query.grouped?
        prepared_result = ActiveSupport::OrderedHash.new
        if query.group_by_column.is_a?(EasyQueryColumn)
          grouped_entities = entities.group_by { |i| query.group_by_column.value(i) }
        else
          grouped_entities = entities.group_by { |i| x = query.group_by_column.custom_value_of(i); (x.value if x).to_s }
        end
        counts = query.entity_count_by_group
        grouped_entities.each do |group, groups_entities|
          # sum
          sum                    = query.send(:summarize_entities, groups_entities, group)
          prepared_result[group] = { :entities => groups_entities, :sums => sum, :count => (counts[group] || groups_entities.count) }
        end
        entities = prepared_result
      else
        yield nil, { :entities => entities, :sums => {} }
        return
      end
    end
    raise ArgumentError, 'Please provide a prepared result to entities grouped list' unless entities.is_a?(Hash)

    entities.each do |group, attributes|
      yield group, attributes
    end
  end

  def easy_query_entity_list(entities)
    if entities.first.class.respond_to?(:each_with_easy_level)
      entities.first.class.each_with_easy_level(entities) do |entity, level|
        yield entity, level
      end
    else
      entities.each do |entity|
        yield entity, nil
      end
    end
  end

  def easy_query_column_header(query, column, options = {})
    if !options[:disable_sort] && column.sortable
      if page_module = options[:page_module].presence
        easy_page_module_sort_header_tag(page_module, query, column.name.to_s,
                                         { class:                      column.css_classes,
                                           caption:                    column.caption,
                                           default_order:              column.default_order,
                                           "data-resizable-column-id": column.name
                                         })
      else
        sort_header_tag(column.name.to_s, { class:                      column.css_classes,
                                            caption:                    column.caption,
                                            default_order:              column.default_order,
                                            "data-resizable-column-id": column.name
        })
      end
    else
      content_tag(:th, column.caption, { class: column.css_classes, "data-resizable-column-id": column.name })
    end
  end

  def options_for_filters(filters, query, reject_used = true)
    grouped_options      = ActiveSupport::OrderedHash.new { |hash, key| hash[key] = [] }
    most_used_group_name = l(:label_most_used)

    # Set order by query settings
    query.filter_groups_ordering.each do |group_name|
      grouped_options[group_name]
    end

    # Select unused filters for selecting
    filters.each do |name, definition|
      if !query.has_filter?(name) || !reject_used
        group        = definition[:group] || l(:label_filter_group_unknown)
        def_lang_key = name.to_s.gsub(/_id$/, '')
        filter       = [definition[:name] || l('field_' + def_lang_key), name]

        grouped_options[group] << filter
        grouped_options[most_used_group_name] << filter if definition[:most_used]
      end
    end

    grouped_options.delete_if { |_, filters| filters.blank? }

    # Copied grouped_options_for_select (due to ordering ...)
    body = ''

    grouped_options.each do |group, filters|
      body << content_tag(:optgroup, options_for_select(filters), label: group)
    end

    body.html_safe
  end

  def easy_query_selected_values(query, field_id)
    if (av_filter = query.available_filters[field_id]) && av_filter[:values]
      filter_options   = query.filters[field_id]
      av_filter_values = av_filter[:values].is_a?(Proc) ? av_filter[:values].call : av_filter[:values]
      v                = av_filter_values.select { |v| v.is_a?(Array) ? filter_options[:values].include?(v[1]) : filter_options[:values].include?(v) }.collect { |v| Array.wrap(v)[0] }.join(', ') if av_filter_values && filter_options && filter_options[:values].is_a?(Array)
    end
    av_filter ||= {}
    unless av_filter[:klass].is_a?(Class)
      assoc             = field_id.gsub('_id', '')
      ref               = query.entity.reflect_on_association(assoc.to_sym)
      av_filter[:klass] = ref.klass if ref
    end
    if av_filter[:klass]
      v ||= Array.wrap(query.objects_for(field_id, av_filter[:klass])).join(', ')
    else
      v ||= Array.wrap(query.values_for(field_id)).join(', ')
    end
    v || ''
  end

  def format_value_for_export(entity, column, unformatted_value = nil, options = {})
    # Entity is Class and it isn't instance. !
    # Sums rows
    if entity.is_a?(Class)
      entity_class = entity
      entity       = nil
    else
      entity_class = entity.class
    end

    column_value = unformatted_value || (entity && column.value(entity))

    # value = Sanitize.clean(format_entity_attribute(entity_class, column, column_value, {:entity => entity, :no_html => true}.merge(options)).to_s, :output => :html).gsub(/\A[[:space:]]+|[[:space:]]+\z/, '').strip
    if column.is_a?(EasyExtensions::EasyQueryExtensions::Groupable::GroupByColumns)
      value = format_groupby_entity_attribute(entity_class, column, column_value, { :entity => entity, :no_html => true }.merge(options))
    else
      value = format_entity_attribute(entity_class, column, column_value, { :entity => entity, :no_html => true }.merge(options)).to_s
    end
    value = ActionController::Base.helpers.strip_tags(value) if options[:no_html] || options[:no_html].nil?
    value = value.gsub(/\A[[:space:]]+|[[:space:]]+\z/, '').strip
    value = value.to_s.gsub('.', l(:general_csv_decimal_separator)) if column_value && (column_value.is_a?(Float) || column_value.is_a?(BigDecimal))

    return CGI.unescapeHTML(value)
  end

  def easy_query_custom_formatting_css(query, entity)
    return '' if query.nil? || entity.nil? || query.custom_formatting.blank?
    query.custom_formatting_entities[entity.id]
  end

  def easy_query_form_buttons_bottom(query, options = {})
    options[:easy_query_form_buttons_bottom_render_method] ||= 'list'
    method                                                 = "render_#{query.type.underscore}_form_buttons_bottom_on_#{options[:easy_query_form_buttons_bottom_render_method]}"
    if respond_to?(method)
      return send(method, query, options)
    end
  end

  def easy_query_group_by_title_tags(query, count, percent, sums = nil, options = {})
    sums ||= {}; options ||= {}
    a    = Array.new

    a << count

    sums.each do |column, sum|
      next unless query.columns.include?(column)
      if options[:plain]
        a << column.caption + ': ' + format_entity_attribute(query.entity, column, sum.to_f, options).to_s
      else
        a << column.caption + ': ' + format_html_entity_attribute(query.entity, column, sum.to_f, options).to_s
      end
    end unless options[:hide_sums]

    if percent.present?
      percent = percent.to_f
      value   = number_to_percentage(percent, :precision => percent.zero? ? 0 : 2)

      if options[:plain]
        a << value
      else
        a << content_tag(:span, value, :class => 'easy-query-title-percent-tag')
      end
    end

    if options[:plain]
      html = a.join(' , ')
    else
      html = ''
      Array(a).each do |info|
        html << content_tag(:span, raw(info), :class => 'count')
      end
    end
    html.html_safe
  end

  def easy_query_summary_row(query, sums = {}, sum_type = :bottom, options = {})
    return ''.html_safe if sums[sum_type].blank?
    s = ''
    s << content_tag(:td, '', :class => 'easy-entity-list__item-placeholder')
    s << content_tag(:td, '', :class => 'easy-entity-list__item-checkbox checkbox') if options[:modal_selector] || options[:hascontextmenu]
    query.columns.each do |column|
      if column.sumable? && column.sumable_bottom?
        value   = format_html_entity_attribute(query.entity, column, sums[sum_type][column])
        content = content_tag(:label, column.caption, :class => 'easy-entity-list__item-attribute-label')
        content << content_tag(:div, value, :class => 'easy-entity-list__item-attribute-content')
        s << content_tag(:td, content, :class => 'easy-entity-list__item-attribute easy-entity-list__item-attribute--sum' + column.css_classes)
      else
        s << content_tag(:td, '', :class => 'easy-entity-list__item-placeholder' + column.css_classes)
      end
    end
    s << content_tag(:td, '', :class => 'easy-entity-list__item-placeholder')

    return content_tag(:tr, s, :class => 'easy-entity-list__item easy-entity-list__item--summary summary', :data => { :uniq_id => options[:uniq_id] })
  end

  def options_for_columns(query, column_collection, selected_key, disabled_columns)
    grouped_options      = ActiveSupport::OrderedHash.new { |hash, key| hash[key] = [] }
    most_used_group_name = l(:label_most_used)
    others_group         = []

    # Set order by query settings
    query.column_groups_ordering.each do |group_name|
      grouped_options[group_name]
    end

    permitted_columns(column_collection).each do |column|

      option = [column.caption(true), column.name]
      if column.other_group?
        others_group << option
      else
        grouped_options[column.group] << option
      end
      grouped_options[most_used_group_name] << option if column.most_used
    end

    grouped_options[l(:label_column_group_other)] = others_group if others_group.any?
    grouped_options.delete_if { |_, columns| columns.blank? }
    grouped_options.each { |_, columns| columns.sort_by!(&:first) }

    grouped_options_for_select(grouped_options, { selected: selected_key, disabled: disabled_columns })
  end

  def options_for_available_columns(query)
    options_for_columns(query, query.available_columns, nil, query.columns.map(&:name))
  end

  def options_for_groupable_columns(query, selected_key = nil)
    options_for_columns(query, query.groupable_columns, selected_key, nil)
  end

  def options_for_sumable_columns(query, selected_key = nil)
    options_for_columns(query, query.sumable_columns, selected_key, nil)
  end

  def options_for_date_columns(query, selected_key = nil)
    options_for_columns(query, query.date_columns, selected_key, nil)
  end

  def query_selected_columns_options(query)
    permitted_columns(query.columns & query.available_columns).collect { |column| [column.caption(true), column.name] }
  end

  def permitted_columns(columns)
    columns.reject { |c| c.frozen? || !c.permitted? }
  end

  def query_period_name(query, period_idx)
    cpsd = query.current_period_start_date(period_idx)
    case query.period_zoom.to_s
    when 'day'
      format_date(cpsd)
    when 'week'
      "#{cpsd.cweek} - #{format_date(cpsd)}"
    when 'month'
      month_name(cpsd.month)
    when 'quarter'
      quarter_name(fiscal_quarter_shift(query, cpsd.month) / 3)
    when 'year'
      cpsd.year.to_s
    end
  end

  def fiscal_quarter_shift(query, current_period_start_month)
    query.period_date_period&.include?('fiscal') ? current_period_start_month - (EasySetting.value('fiscal_month').to_i - 1) : current_period_start_month
  end

  def query_period_zoom_name(zoom)
    l("button_gantt_zoom_#{zoom}")
  end

  def export_to_csv(entities, query, options = {})
    EasyExtensions::Export::Csv.new(query, self, options.merge(entities: entities)).output
  end

  def export_to_pdf(entities, query, options = {})
    if entities.is_a?(Array)
      return export_to_pdf_old(entities, query)
    end

    EasyExtensions::Export::Pdf.new(entities, query, options).output
  end

  def export_to_xlsx(entities, query, options = {})
    return '' if entities.is_a?(Array)
    EasyExtensions::Export::Xlsx.new(entities, query, options).output
  end

  def export_to_pdf_old(entities, query)
    name = query.class.to_s.tableize
    pdf  = ITCPDF.new(current_language)
    pdf.SetTitle(l("label_#{name}_plural"))
    pdf.alias_nb_pages
    pdf.footer_date = format_date(Date.today)
    pdf.AddPage("L")

    # title
    pdf.SetFontStyle('B', 11)
    pdf.RDMCell(190, 10, l("label_#{name}_plural"))
    pdf.Ln

    row_height = 5
    col_width  = Array.new
    query.columns.each do |column|
      case column.name
      when :admin
        col_width << 0.4
      when :login, :firstname, :last_login_on, :created_on, :name
        col_width << 1
      when :lastname
        col_width << 1.5
      when :mail, :groups
        col_width << 2
      else
        col_width << 0.5
      end
    end
    ratio     = 262.0 / col_width.inject(0) { |s, w| s += w }
    col_width = col_width.collect { |w| w * ratio }

    # headers
    pdf.SetFontStyle('B', 8)
    pdf.SetFillColor(230, 230, 230)
    query.columns.each do |column|
      if column.name == :admin
        pdf.RDMCell(col_width[query.columns.index(column)], row_height, 'Adm.', 1, 0, 'L', 1)
      else
        pdf.RDMCell(col_width[query.columns.index(column)], row_height, column.caption.to_s, 1, 0, 'L', 1)
      end
    end
    pdf.Ln

    #rows
    pdf.SetFontStyle('', 8)
    pdf.SetFillColor(255, 255, 255)
    previous_group = false
    entities.each do |entity|
      if query.grouped? && (group = query.group_by_column.value(entity)) != previous_group
        pdf.SetFontStyle('B', 9)
        pdf.RDMCell(col_width.sum, row_height,
                    (group.blank? ? 'None' : group.to_s) + " (#{query.entity_count_by_group[group]})",
                    1, 1, 'L')
        pdf.SetFontStyle('', 8)
        previous_group = group
      end
      query.columns.each do |column|
        pdf.RDMCell(col_width[query.columns.index(column)], row_height, format_value_for_export(entity, column), 1, 0, 'L', 1)
      end
      pdf.Ln
    end
    pdf.Output
  end

  def easy_render_format_options_dialog(query, groups, params, format)
    @format_options_dialog_rendered ||= {}
    return if @format_options_dialog_rendered[format]
    @format_options_dialog_rendered[format] = true
    render(:partial => 'common/easy_format_options_dialog', :locals => { :query => query, :groups => groups, :params => params, :format => format })
  end

  def tagged_query_heading(tagged_query, hide_counts)
    heading = "<span class=\"entity-name\">#{tagged_query.name}</span>"
    heading << " (<span class=\"entity-count\">#{tagged_query.entity_count}</span>)" unless hide_counts
    heading.html_safe
  end

  def easy_easy_query_query_additional_ending_buttons(entity, options = {})
    s = ''
    s << link_to(l(:button_edit), edit_easy_query_path(entity, back_url: edit_easy_query_management_path(type: entity.type)), :class => 'icon icon-edit', :title => l(:title_edit_projectquery))
    s << link_to(l(:button_delete), easy_query_path(entity, back_url: edit_easy_query_management_path(type: entity.type)), :data => { :confirm => l(:text_are_you_sure) }, :method => 'delete', :class => 'icon icon-del', :title => l(:title_delete_projectquery))
    s.html_safe
  end

  def render_query_sort_criteria(query, options = {}, &block)
    partial     = options[:partial] || 'easy_queries/easy_query_sort_criteria'
    items_count = options[:items_count] || 3

    sortable_columns_options = query.available_columns.reduce([]) do |opts, c|
      opts.push([c.caption, c.name.to_s]) if c.sortable?
      opts
    end
    sorting_options          = [
        [l(:label_ascending), 'asc'],
        [l(:label_descending), 'desc']
    ]

    options.merge!(
        sortable_columns_options: sortable_columns_options.sort,
        sorting_options:          sorting_options
    )
    output = Array.new(items_count) do |i|
      result = ''
      options.merge!(
          item:                              i,
          sortable_columns_options_selected: query.sort_criteria_key(i),
          sorting_options_selected:          query.sort_criteria_order(i)
      )
      result += capture(i, &block) if block_given?
      result += render(partial, options)
      result
    end
    concat(output.join('<br />').html_safe)
  end

end
