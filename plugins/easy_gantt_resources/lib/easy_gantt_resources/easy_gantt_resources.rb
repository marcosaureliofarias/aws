module EasyGanttResources

  def self.default_resources_start_date
    Date.today - 1.month
  end

  def self.default_resources_end_date
    Date.today + 2.month
  end

  def self.easy_attendace_enabled?
    EasyGantt.easy_extensions? && EasyAttendance.enabled?
  end

  # TODO: Use constant
  def self.allocators(with_labels: false, include_default: false, include_random: false)
    available_allocators = ['from_end', 'from_start', 'evenly', 'future_from_end', 'future_from_start', 'future_evenly']

    if include_random
      available_allocators << 'random'
    end

    if with_labels
      available_allocators.map! do |alloc|
        [I18n.t("easy_gantt_resources.allocator.#{alloc}"), alloc]
      end
    end

    if include_default
      default_value = if with_labels
          [I18n.t('field_default_allocator'), '']
        else
          ''
        end

      available_allocators.unshift(default_value)
    end

    available_allocators
  end

  # Return holidays from selected users
  #
  #   {
  #     user_id: {
  #       date: [*holidays]
  #     }
  #   }
  #
  def self.users_holidays(users, from, to)
    result = {}
    years = from.year.upto(to.year)
    calendar_holidays = {}

    calendars = EasyUserWorkingTimeCalendar.where(user_id: users).
                                            preload(:holidays, parent: :holidays)

    calendars.each do |calendar|
      user_id = calendar.user_id
      calendar = (calendar.parent.nil? ? calendar : calendar.parent)
      calendar_holidays[calendar.id] ||= begin
        events = Hash.new { |hash, key| hash[key] = [] }
        calendar.holidays.each do |holiday|
          if holiday.is_repeating?
            years.each do |year|
              date = holiday.holiday_date.change(year: year)
              if date.between?(from, to)
                events[date] << holiday
              end
            end
          else
            date = holiday.holiday_date
            if date.between?(from, to)
              events[date] << holiday
            end
          end
        end
        events
      end
      result[user_id] = calendar_holidays[calendar.id]
    end

    result
  end

  def self.user_easy_gantt_resource_attributes_from_params(user, user_params)
    user_params ||= {}

    user.easy_gantt_resources_estimated_ratio      = user_params['easy_gantt_resources_estimated_ratio'] if user_params['easy_gantt_resources_estimated_ratio'].present?
    user.easy_gantt_resources_hours_limit          = user_params['easy_gantt_resources_hours_limit']     if user_params['easy_gantt_resources_hours_limit'].present?

    if easy_gantt_resources_advance_hours_limits = user_params['easy_gantt_resources_advance_hours_limits']

      if easy_gantt_resources_advance_hours_limits.is_a?(Array) # JSON
        user.easy_gantt_resources_advance_hours_limits = easy_gantt_resources_advance_hours_limits
      elsif easy_gantt_resources_advance_hours_limits.has_key?('easy_gantt_resources_advance_hours_limit') # XML
        user.easy_gantt_resources_advance_hours_limits = easy_gantt_resources_advance_hours_limits['easy_gantt_resources_advance_hours_limit']
      end

    end
  end

end
