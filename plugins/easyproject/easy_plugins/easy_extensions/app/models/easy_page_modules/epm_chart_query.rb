class EpmChartQuery < EpmEasyQueryBase

  def self.translatable_keys
    result = super
    result << %w[chart_settings y_label]
    result
  end

  def category_name
    'charts'
  end

  def edit_path
    'easy_page_modules/charts/chart_query_edit'
  end

  def get_query_class(settings)
    settings['easy_query_type'].safe_constantize if settings['easy_query_type']
  end

  def output(settings)
    'chart'
  end

  def show_preview?
    false
  end

  def caching_available?
    Rails.cache.class.name == 'ActiveSupport::Cache::FileStore' ? true : false
  end

  def cache_on?(settings)
    super && settings['cache_on'] == '1'
  end

  def primary_renderer(settings, **options)
    (settings['chart_settings'] && settings['chart_settings']['primary_renderer']) || 'bar'
  end

  def get_edit_data(settings, user, page_context = {})
    additional_queries         = {}
    settings['chart_settings'] ||= {}
    settings['chart_settings']['additional_queries'].each do |key, query_settings|
      q_cls = query_settings['easy_query_type'].constantize rescue nil
      next unless q_cls
      q = q_cls.new
      q.from_params(query_settings)
      q.project               = page_context[:project] if page_context[:project]
      q.output                = output(query_settings) || 'chart'
      q.export_formats        = {}
      additional_queries[key] = q
    end if settings['chart_settings']['additional_queries'].is_a?(Hash)
    super.merge(additional_queries: additional_queries)
  end

  def get_query(settings, user, page_context = {})
    set_primary_renderer(settings)
    settings['query_name'] ||= (get_query_class(settings) ? get_query_class(settings).translated_name + ' - ' : '') + translated_name
    query                  = super

    # Prepend additionals filters
    # Filters will be applied in chart output
    if query && settings['chart_settings'] && settings['chart_settings']['additional_queries'].is_a?(Hash)
      settings['chart_settings']['additional_queries'].each do |key, query_settings|
        add_additional_filters_from_global_filters!(page_context, query_settings)
      end
    end

    query
  end

  def set_primary_renderer(settings)
    settings['chart_settings']                     ||= {}
    settings['chart_settings']['primary_renderer'] = primary_renderer(settings)
  end

end
