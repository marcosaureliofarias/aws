class EpmGenericGauge < EasyPageModule

  def self.translatable_keys
    result = [%w[name]]
    0.upto(2).each do |idx|
      result << ['tags', idx.to_s, 'name']
    end

    result
  end

  def self.css_icon
    'icon icon-report'
  end

  def css_class

  end

  def category_name
    @category_name ||= 'charts'
  end

  def get_show_data(settings, user, page_context = {})
    current_tag = settings['current_tag'].presence || '0'

    if needle_query = create_query_from_settings(settings, 'needle', current_tag, page_context)
      column = needle_query.get_column(settings['needle_query_sumable_column']) || needle_query.get_column(settings['sumable_column'])
      value  = (column && column.sumable? ? needle_query.entity_sum(column) : 0)
    else
      value = 0
    end

    case settings['action_range']
    when 'dynamic_range'
      if range_query = create_query_from_settings(settings, 'range', current_tag, page_context)
        column    = range_query.get_column(settings['range_query_sumable_column'])
        max_value = (column && column.sumable? ? range_query.entity_sum(column).to_f : 0)
      end
    else
      settings['tags'] ||= {}
      max_value        = settings['tags'][current_tag]['plan'].to_f if settings['tags'][current_tag]
    end

    max_value = max_value.to_f

    if page_zone_module
      page_zone_module.css_class = 'easy-page__module--gauge'
      page_zone_module.floating  = false
    end

    { value: value, max_value: max_value, query: needle_query }
  end

  def get_edit_data(settings, user, page_context = {})
    needle_queries = create_queries_from_settings(settings, 'needle', page_context)
    range_queries  = create_queries_from_settings(settings, 'range', page_context) if settings['action_range'] == 'dynamic_range'
    range_queries  ||= {}
    needle_query   = needle_queries.first[1] if needle_queries.present?
    range_query    = range_queries.first[1] if range_queries.present?

    needle_column  = needle_query.get_column(settings['needle_query_sumable_column']) || needle_query.sumable_columns.first if needle_query
    range_column   = range_query.get_column(settings['range_query_sumable_column']) || range_query.sumable_columns.first if range_query

    { needle_query: needle_query, needle_queries: needle_queries, needle_column: needle_column,
      range_query:  range_query, range_queries: range_queries, range_column: range_column, available_query_subclasses: available_query_subclasses }
  end

  private

  def create_queries_from_settings(settings, prefix, page_context = {})
    queries = {}
    0.upto(2).each do |idx|
      queries[idx] = create_query_from_settings(settings, prefix, idx, page_context)
    end
    queries
  end

  def create_query_from_settings(settings, prefix, tag_idx, page_context = {})
    settings['tags'] ||= {}
    query            = create_query(settings["#{prefix}_easy_query_klass"]) if settings["#{prefix}_easy_query_klass"].present?
    query_settings   = settings['tags'][tag_idx.to_s]["#{prefix}_easy_query_settings"] if settings['tags'][tag_idx.to_s]
    if query.nil? && prefix == 'needle' && settings['easy_query_klass'].present?
      query          = create_query(settings['easy_query_klass'])
      query_settings = settings['tags'][tag_idx.to_s]['easy_query_settings'] if settings['tags'][tag_idx.to_s]
    end
    set_query(query, settings["#{prefix}_query_easy_currency_code"], query_settings || {}, page_context) if query
    query
  end

  def set_query(query, currency = nil, query_settings = nil, page_context = {})
    add_additional_filters_from_global_filters!(page_context, query_settings)

    query.easy_currency_code     = currency.presence
    query.project                = page_context[:project]
    query_settings['set_filter'] = '1' if query_settings
    query.from_params(query_settings)
  end

  def available_query_subclasses
    @available_query_subclasses ||= EasyQuery.constantized_subclasses.select { |q| q.chart_support? && q.no_params_url_support? && q.new.sumable_columns? }
  end

  def create_query(name)
    @gauge_queries ||= {}
    return @gauge_queries[name] && @gauge_queries[name].dup.tap { |q| q.filters = {} } if @gauge_queries.has_key?(name)
    query_class = name.classify.safe_constantize
    if query_class && query_class.no_params_url_support? && query_class.chart_support?
      query = query_class.new
      if query.sumable_columns?
        @gauge_queries[name] = query
      end
    end
    @gauge_queries[name] ||= nil
  end

end
