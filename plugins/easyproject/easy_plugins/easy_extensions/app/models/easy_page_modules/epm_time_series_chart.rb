# frozen_string_literal: true

##
# Show queries on timeline
#
# Current page modules save one query and others
# as `additional_queries`
#
# This module save all queries into `queries`
# and module settings into `config`.
# => Only these keys should be used!!!
#
# Because our system depends on "one-query-behaviour"
# this page module prepare data before rendering.
# It means that first query is taken as the main.
#
class EpmTimeSeriesChart < EpmEasyQueryBase

  def category_name
    'charts'
  end

  def show_path
    'easy_page_modules/easy_query_show'
  end

  def edit_path
    'easy_page_modules/charts/time_series_chart_edit'
  end

  def get_main_query_settings(settings, page_context)
    main_query_settings = nil
    queries_settings    = settings['queries']

    if !queries_settings.is_a?(Hash)
      return
    end

    queries_settings.each do |key, query_settings|
      if query_settings['easy_query_type'].blank?
        next
      end

      # All queries depends on some main page module settings
      query_settings['period_zoom']                        = settings.dig('config', 'period_zoom')
      query_settings['easy_currency_code']                 = settings.dig('config', 'easy_currency_code')
      query_settings['chart_settings']                     ||= {}
      query_settings['chart_settings']['primary_renderer'] = 'line'

      add_additional_filters_from_global_filters!(page_context, query_settings)

      if main_query_settings
        main_query_settings['chart_settings']['additional_queries'][key] = query_settings
      else
        main_query_settings                                         = query_settings
        main_query_settings['chart_settings']['additional_queries'] = {}
      end
    end

    main_query_settings
  end

  def get_show_data(settings, user, page_context = {})
    # Build saved queries settings into one
    main_query_settings = get_main_query_settings(settings, page_context)
    return {} if main_query_settings.nil?

    # Queries are "build" but user can temporarily change something
    # (for example period zoom)
    main_query_settings = main_query_settings.merge(settings)

    query = EasyQuery.new_subclass_instance(main_query_settings['easy_query_type'])
    return {} if query.nil?

    query.name    = settings.dig('config', 'title')
    query.project = page_context[:project]
    query.from_params(main_query_settings)
    query.output = 'chart'

    { query: query }
  end

  def get_edit_data(settings, user, page_context = {})
    queries          = {}
    queries_settings = settings['queries']

    if queries_settings.is_a?(Hash) || queries_settings.is_a?(ActionController::Parameters)
      queries_settings.each do |key, query_settings|
        query = get_single_query(settings, query_settings, page_context)

        if query
          queries[key] = query
        end
      end
    end

    { queries: queries }
  end

  def get_single_query(settings, query_settings, page_context)
    query = EasyQuery.new_subclass_instance(query_settings['easy_query_type'])
    return if query.nil?

    query.name    = settings.dig('config', 'title')
    query.project = page_context[:project]
    query.from_params(query_settings)
    query.output = 'chart'
    query
  end

end
