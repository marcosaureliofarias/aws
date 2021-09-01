class EpmTrends < EasyPageModule

  OPERATORS = ['>', '-', '+', '/', '*']

  TRANSLATABLE_KEYS = [
      %w[name],
      %w[description]
  ]

  def self.default_trend_name(page_module)
    query_name = page_module.settings['easy_query_type']&.underscore

    page_module.module_definition.translated_name + ' - ' + I18n.t("easy_query.name.#{query_name}", default: I18n.t('easy_page_module.issue_query.adhoc_query_default_text'))
  end

  def category_name
    'others'
  end

  def get_query_class(settings, suffix = nil)
    EasyQuery.new_subclass_instance(settings["easy_query_type#{suffix}"]) if settings["easy_query_type#{suffix}"].present?
  end

  def custom_end_buttons?
    false
  end

  def show_preview?
    true
  end

  def collapsible?
    false
  end

  def query_module?
    true
  end

  def available_query_subclasses
    @available_query_subclasses ||= EasyQuery.constantized_subclasses.select { |q| q.chart_support? && q.no_params_url_support? }
  end

  def get_show_data(settings, user, page_context = {})
    query = get_query(settings, user, page_context)
    return { number_to_show: nil } unless query

    operator                   = settings['operator']
    compere_to_previous_period = settings['compere_to_previous_period'].to_boolean
    use_query_to_compare       = settings['use_query_to_compare'].to_boolean

    if use_query_to_compare
      query_to_compare = get_query_to_compare(query, settings, page_context)
    elsif compere_to_previous_period
      query_to_compare                     = get_query_to_compare_for_previous_period(query, settings)
      settings['column_to_sum_to_compare'] = settings['column_to_sum']
      settings['type_to_compare']          = settings['type']
      operator                             = '>'
    end

    if page_zone_module
      page_zone_module.floating  = true
      page_zone_module.css_class = (settings['color'] || 'palette-1') + ' easy-page__module--trend'
    end

    # Both options. Can be used when needs data series to compare to previous period
    show_trend_for_previous_period = compere_to_previous_period && use_query_to_compare && query_to_compare.present?

    get_data(query, settings, query_to_compare, operator, show_trend_for_previous_period)
  end

  def get_edit_data(settings, user, page_context = {})
    query = get_query_class(settings)
    return { query: nil, available_query_subclasses: available_query_subclasses } unless query

    query.project = page_context[:project] if page_context[:project]

    if settings['query_type'] == '2'
      query.from_params(settings['query'])
    end

    query.output         = []
    query.export_formats = {}

    query_to_compare     = get_query_to_compare(query, settings, page_context) if settings['use_query_to_compare']

    { query: query, query_to_compare: query_to_compare, available_query_subclasses: available_query_subclasses }
  end

  def before_from_params(page_module, params)
    if params && page_module['easy_query_type'] != params['easy_query_type']
      page_module.settings.delete(:query)
      page_module.settings.delete(:query_to_compare)
      page_module.settings.delete(:type)
      page_module.settings.delete(:column_to_sum)
    end
    if params && page_module['easy_query_type_to_compare'] != params['easy_query_type_to_compare']
      page_module.settings.delete(:type_to_compare)
    end
    super
  end

  private

  def get_query_to_compare_for_previous_period(query, settings)
    new_query         = query.dup
    new_query.filters = query.filters.dup
    new_query.filters.each do |name, setting|
      next unless (new_query.available_filters[name] && new_query.available_filters[name][:type] == :date_period)
      period = setting['values']['period']
      if period.is_a?(String) && period.include?('<<')
        _period, new_shift = period.split('<<')
        shift              ||= new_shift.to_i
      end
      setting['values']['shift'] = shift ? shift - 1 : -1
    end
    new_query
  end

  def get_query_to_compare(query, settings, page_context = {})
    if !settings['easy_query_type_to_compare'].present?
      query = query.dup
    else
      query = get_query_class(settings, '_to_compare')
      return nil unless query

      query.project = page_context[:project] if page_context[:project]
    end
    set_column_names(query, settings, '_to_compare')
    query.filters = {}
    query_params  = settings['query_to_compare']
    return query unless query_params
    query.easy_currency = EasyCurrency.activated.find_by(iso_code: query_params['easy_currency_code']) if query_params['easy_currency_code'].present?

    if query_params['fields'] && query_params['fields'].is_a?(Array)
      query_params['values'] ||= {}
      query_params['fields'].each do |field|
        query.add_filter(field, query_params['operators'][field], query_params['values'][field])
      end
    elsif query_params['f'].is_a?(Hash)
      query_params['f'].each do |field, expression|
        query.add_short_filter(field, expression)
      end
    else
      query.available_filters.each_key do |field|
        query.add_short_filter(field, query_params[field]) if query_params[field]
      end
    end

    add_additional_filters_from_global_filters!(page_context, query_params)
    additional_filters = query_params.fetch('additional_filters', {})
    additional_filters.each do |field, value|
      query.add_short_filter(field, value)
    end

    query
  end

  def get_query(settings, user, page_context = {})
    query = get_query_class(settings)
    return nil unless query

    add_additional_filters_from_global_filters!(page_context, settings['query'])

    query.project = page_context[:project] if page_context[:project]
    settings.delete('query_id')
    query.from_params(settings['query'])
    query.output = []

    set_column_names(query, settings)

    query
  end

  def set_column_names(query, settings, suffix = nil)
    if settings["type#{suffix}"] == 'sum' && query.get_column(settings["column_to_sum#{suffix}"]).try(:sumable?)
      query.column_names = [settings["column_to_sum#{suffix}"].try(:to_sym)]
    else
      query.column_names = []
    end
  end

  def get_data(query, settings, query_to_compare = nil, operator = nil, show_trend_for_previous_period = false)
    query_number = sum_or_count(query, settings)
    if query_to_compare
      number_to_compare = sum_or_count(query_to_compare, settings, '_to_compare')
      if show_trend?(true, operator)
        trend = direction_of_trend(query_number, operator, number_to_compare)
      else
        result = calculation(query_number, operator, number_to_compare)
      end
    end
    number_to_show = result.presence || query_number || 0

    trend_options                     = get_trend_options(query_to_compare, operator, number_to_show, number_to_compare, trend)
    trend_options_for_previous_period = get_trend_options_for_previous_period(query, settings, query_to_compare, operator, number_to_show, show_trend_for_previous_period)

    show_result_as_percentage = show_result_as_percentage(settings, operator)
    number_to_show            *= 100 if show_result_as_percentage

    { query:                     query,
      operator:                  operator,
      number_to_show:            number_to_show,
      query_to_compare:          query_to_compare,
      number_to_compare:         number_to_compare,
      show_result_as_percentage: show_result_as_percentage }.merge(trend_options).merge(trend_options_for_previous_period)
  end

  def sum_or_count(query, settings, suffix = nil)
    if settings["type#{suffix}"] == 'sum'
      return nil if query.column_names.empty?
      query.entity_sum(settings["column_to_sum#{suffix}"].to_sym)
    else
      query.entity_count
    end
  end

  def icon_class(trend)
    return 'easy-trend__direction--up' if trend == 1
    return 'easy-trend__direction--down' if trend == -1
    return 'easy-trend__direction--stagnant'
  end

  def calculation(number, operator, second_number)
    calculation_result = nil
    return nil if !number || !second_number
    case operator
    when '-'
      calculation_result = number - second_number
    when '+'
      calculation_result = number + second_number
    when '/'
      calculation_result = (number.to_f / second_number.to_f)
    when '*'
      calculation_result = number * second_number
    end
    calculation_result
  end

  def direction_of_trend(number, operator, second_number)
    trend = nil
    case operator
    when '>'
      trend = number <=> second_number
    end
    trend
  end

  def show_trend?(use_query_to_compare, trend_operator)
    return true if use_query_to_compare && trend_operator == '>'
    false
  end

  def trend_percent(number, second_number)
    return 0 if number == second_number
    ((number.to_f / second_number.to_f) - 1) * 100
  end

  def get_trend_options_for_previous_period(query, settings, query_from_data_series, operator, number, show_trend_for_previous_period)
    result                                  = {}
    result[:show_trend_for_previous_period] = show_trend_for_previous_period
    return result unless result[:show_trend_for_previous_period]

    query_to_compare                  = get_query_to_compare_for_previous_period(query, settings)
    query_from_data_series_to_compare = get_query_to_compare_for_previous_period(query_from_data_series, settings)

    query_number      = sum_or_count(query_to_compare, settings)
    number_to_compare = sum_or_count(query_from_data_series_to_compare, settings, '_to_compare')

    number_to_show    = calculation(query_number, operator, number_to_compare) if operator != '>'
    trend             = direction_of_trend(query_number, operator, number_to_compare)
    number_to_show    = number_to_show.presence || query_number

    result[:number_for_previous_period]        = number_to_show
    result[:trend_percent_for_previous_period] = trend_percent(number, number_to_show)
    result[:trend_icon_for_previous_period]    = icon_class(trend)
    result
  end

  def show_result_as_percentage(settings, operator)
    settings['use_query_to_compare'].to_boolean && settings['show_as_percentage'].to_boolean && operator == '/'
  end

  def get_trend_options(query_to_compare, operator, number_to_show, number_to_compare, trend)
    result              = {}
    result[:show_trend] = show_trend?(query_to_compare, operator)
    if result[:show_trend]
      result[:trend_percent] = trend_percent(number_to_show, number_to_compare)
      result[:trend_icon]    = icon_class(trend)
    end

    result
  end
end
