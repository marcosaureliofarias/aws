class EpmAttendance < EasyPageModule

  TRANSLATABLE_KEYS = [
      %w[query_name]
  ]

  def category_name
    @category_name ||= 'others'
  end

  def permissions
    @permissions ||= [:view_easy_attendances]
  end

  def default_settings
    @default_settings ||= HashWithIndifferentAccess.new('query_type'   => '2', 'outputs' => ['calendar'], 'period' => 'week',
                                                        'column_names' => EasySetting.value('easy_attendance_query_list_default_columns'),
                                                        'fields'       => ['arrival', 'user_id'],
                                                        'operators'    => HashWithIndifferentAccess.new('arrival' => 'date_period_1', 'user_id' => '='),
                                                        'values'       => HashWithIndifferentAccess.new('arrival' => HashWithIndifferentAccess.new('period' => 'current_week'), 'user_id' => ['me'])
    )
  end

  def runtime_permissions(user)
    EasyAttendance.enabled?
  end

  def custom_end_buttons?
    false
  end

  def show_preview?
    true
  end

  def page_module_toggling_container_options_helper_method
    'get_epm_easy_query_base_toggling_container_options'
  end

  def get_show_data(settings, user, page_context = {})
    query, easy_user_working_time_calendar = nil, nil

    prepared_result_entities = Hash.new

    if settings['query_type'] == '2'
      add_additional_filters_from_global_filters!(page_context, settings)

      query         = EasyAttendanceQuery.new(:name => settings['query_name'])
      query.filters = {}
      query.from_params(settings)
    elsif !settings['query_id'].blank?
      begin
        query = EasyAttendanceQuery.find(settings['query_id'])
      rescue ActiveRecord::RecordNotFound
      end
    end

    if query
      period = (settings['settings'] && settings['settings']['period'].present?) ? settings['settings']['period'].to_sym : (query.settings[:period].try(:to_sym) || :week)

      if output(settings) == 'calendar'
        start_date = begin
          ; settings['start_date'].to_date;
        rescue;
        end
        if start_date
          query.filters.delete(calendar_options[:start_date_filter])
          query.filters.delete(calendar_options[:end_date_filter])
        else
          start_date = user.today
        end

        calendar       = EasyAttendances::Calendar.new(start_date, current_language, period)
        startdt, enddt = calendar.startdt, calendar.enddt

        query.entity_scope = query.entity_scope.
            where(["(#{query.entity.table_name}.#{calendar_options[:start_date_filter]} BETWEEN ? AND ?)", startdt, enddt.end_of_day]).
            order([User.fields_for_order_statement, "#{EasyAttendance.table_name}.arrival"])

        resulted_entities = query.entities(order: nil)

        easy_user_working_time_calendar = get_easy_user_working_time_calendar(query)

        calendar.events = resulted_entities
      else
        row_limit = settings['row_limit'].to_i
        if query.grouped?
          prepared_result_entities = query.groups({ limit: (row_limit > 0 ? row_limit : nil) })
        else
          prepared_result_entities = query.entities({ limit: (row_limit > 0 ? row_limit : nil) })
        end
      end

      easy_attendance = EasyAttendance.new_or_last_attendance(user)

      first_non_closed_attendance = EasyAttendance.where(departure: nil).
          where(['arrival BETWEEN ? AND ?', Date.today - 60, Date.today]).
          where(user_id: user.id).first
    end

    return { query: query, prepared_result_entities: prepared_result_entities, calendar: calendar, easy_attendance: easy_attendance, easy_user_working_time_calendar: easy_user_working_time_calendar, first_non_closed_attendance: first_non_closed_attendance, period: period, start_date: start_date }
  end

  def get_edit_data(settings, user, page_context = {})
    query = EasyAttendanceQuery.new(:name => settings['query_name'] || '')
    query.from_params(settings) if settings['query_type'] == '2'
    query.output = output(settings) || 'list'

    return { :query => query }
  end

  private

  def get_easy_user_working_time_calendar(query)
    return nil unless query.is_a?(EasyQuery)

    if user_filter = query.filters['user_id']
      user_ids = Array(user_filter[:values])

      if user_ids.size == 1
        user_id = user_ids.first
      end

      user_id = User.current.id if user_ids.include?('me')
    end
    EasyUserWorkingTimeCalendar.find_by(user_id: user_id || User.current.id)
  end

  def calendar_options
    { start_date_filter: 'arrival', end_date_filter: 'departure' }
  end

end
