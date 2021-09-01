class EpmEasyQueryBase < EasyPageModule

  def self.translatable_keys
    [
        %w[query_name]
    ]
  end

  def query_class
    raise "please define a #{self.class.name}#query_class method"
  end

  # better than redefine query_class method everywhere
  def get_query_class(_settings)
    query_class
  end

  def show_path
    'easy_page_modules/easy_query_show'
  end

  def edit_path
    'easy_page_modules/easy_query_edit'
  end

  def custom_end_buttons?
    false
  end

  def show_preview?
    true
  end

  def chart_included?(settings = nil)
    settings && output(settings) == 'chart'
  end

  # redefine page_module method - that should be deleted
  def output(settings)
    settings['outputs'].is_a?(Array) ? settings['outputs'].first : settings['output']
  end

  def get_show_data(settings, user, page_context = {})
    query = get_query(settings, user, page_context)

    if page_zone_module && query&.valid?
      case output(settings)
      when 'chart', 'list', 'tiles'
        if page_zone_module.settings['daily_snapshot'] == '1'
          query = get_snapshot_query(query, settings)
        end
        entities = get_entities(query, settings)
      when 'calendar'
        calendar = query.build_calendar(user: user, start_date: (settings['start_date'].to_date rescue nil), period: settings['period'])
      else
        entities = get_entities(query, settings)
      end
    end

    { query: query, entities: entities, calendar: calendar }
  end

  def get_edit_data(settings, user, page_context = {})
    query_klass = get_query_class(settings)
    return { query: nil } unless query_klass

    query         = query_klass.new(name: settings['query_name'] || '')
    query.project = page_context[:project] if page_context[:project]

    if settings['query_type'] == '2'
      settings.delete('query_id')
      query.from_params(settings)
    end

    query.output              = output(settings) || 'list'
    query.export_formats      = {}
    query.easy_query_snapshot = @easy_query_snapshot

    { query: query }
  end

  def page_module_toggling_container_options_helper_method
    'get_epm_easy_query_base_toggling_container_options'
  end

  def before_from_params(page_module, params)
    @default_output = output(page_module.settings)
  end

  def page_zone_module_before_save(epzm)
    if epzm.settings['daily_snapshot'] == '1' && (eqs_attrs = epzm.settings.delete('easy_query_snapshot'))
      epzm.easy_query_snapshot_attributes = eqs_attrs.merge('author_id' => User.current.id)
    elsif epzm.settings['daily_snapshot'] == '0'
      epzm.easy_query_snapshot.mark_for_destruction if epzm.easy_query_snapshot
    end
  end

  def page_zone_module_after_load(epzm)
    @easy_query_snapshot = epzm.easy_query_snapshot
    @easy_query_snapshot_data = @easy_query_snapshot.easy_query_snapshot_data if @easy_query_snapshot
  end

  def get_query(settings, user, page_context = {})
    query_klass = get_query_class(settings)
    return nil unless query_klass

    add_additional_filters_from_global_filters!(page_context, settings)

    if settings['query_type'] == '2'
      query         = query_klass.new(name: settings['query_name'].presence || '_')
      query.project = page_context[:project] if page_context[:project]
      settings.delete('query_id')
      query.from_params(settings)
      query.output = output(settings) || 'list'
    elsif settings['query_id'].present?
      begin
        query         = query_klass.find(settings['query_id'])
        query.project = page_context[:project] if page_context[:project]
        query.set_additional_params(settings)
        query.set_sort_params(settings)
      rescue ActiveRecord::RecordNotFound
      end
    end

    if query && @default_output
      outputs    = RedmineExtensions::EasyQueryHelpers::Outputs.new(query)
      def_output = outputs.available_outputs.detect { |o| o.key == @default_output }
      def_output.apply_settings if def_output
      outputs.each { |o| o.configure_from_defaults unless o.key == @default_output }
    end

    query
  end

  def get_snapshot_query(query, settings)
    snapshot = page_zone_module.easy_query_snapshot

    if snapshot
      snapshot_query = EasyQuerySnapshotDataQuery.new(name: settings['query_name'])
      snapshot_query.source_query = query
      snapshot_query.output = output(settings) || 'list'
      snapshot_query.add_filter "easy_query_snapshot_id", "=", [snapshot.id.to_s]
      snapshot_query.column_names = ["value1"]
      snapshot_query.period_settings = query.period_settings.dup

      snapshot_query.chart_settings = settings['chart_settings'].dup
      if snapshot_query.chart_settings['y_label'].blank?
        snapshot_query.chart_settings['y_label'] = query.inline_columns.select(&:sumable_header?).detect{|c| c.name.to_s == query.chart_settings['axis_y_column'].to_s}.try(:caption)
      end
      snapshot_query.chart_settings['axis_x_column'] = ['date']
      snapshot_query.chart_settings['axis_y_column'] = 'value1'

      snapshot_query.columns[0].title = query.inline_columns.select(&:sumable_header?).first.try(:caption)
  
      snapshot_query
    else
      Rails.logger.error "Snapshot requested but not found for module #{page_zone_module.module_definition.class.to_s} / #{page_zone_module.uuid}"
      query
    end
  end

  def get_entities(query, settings)
    options = { limit: get_row_limit(settings['row_limit']) }.merge(settings[:query_options].to_h)

    if query.grouped? && self.output(settings) != 'calendar'
      query.groups(options)
    else
      query.entities(options)
    end
  end

  def snapshot_supported?
    true
  end

end
