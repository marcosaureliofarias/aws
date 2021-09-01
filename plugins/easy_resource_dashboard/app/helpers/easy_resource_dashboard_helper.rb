module EasyResourceDashboardHelper

  def get_epm_top_user_utilization_toggling_container_options(page_module, options)
    if options[:edit]
      return {}
    end

    epm_data = options[:easy_page_modules_data]

    heading = page_module.settings[:name] || l('easy_pages.modules.top_user_utilization')
    if epm_data[:reverse]
      heading << " (LOWEST #{epm_data[:count]})"
    else
      heading << " (TOP #{epm_data[:count]})"
    end

    { heading: heading }
  end

  def get_epm_users_utilization_toggling_container_options(page_module, options)
    if options[:edit]
      return {}
    end

    epm_data = options[:easy_page_modules_data]

    heading = page_module.settings[:name] || l('easy_pages.modules.users_utilization')
    heading << " (#{ l(:label_next_n_days, days: epm_data[:days]) }) : #{ epm_data[:users].map(&:name).join(', ') }"

    { heading: heading }
  end

  def get_epm_groups_utilization_toggling_container_options(page_module, options)
    if options[:edit]
      return {}
    end

    epm_data = options[:easy_page_modules_data]

    heading = page_module.settings[:name] || l('easy_pages.modules.groups_utilization')
    heading << " (#{ l(:label_next_n_days, days: epm_data[:days]) }) : #{ epm_data[:groups].map(&:name).join(', ') }"

    { heading: heading }
  end

  def max_allocable_hours(user, from, to)
    max_hours_per_day = EasyGanttResource.hours_per_day(user)
    weekend_cwdays = EasyGantt.non_working_week_days(user)
    working_calendar = user.try(:current_working_time_calendar)
    nonworking_attendaces = Hash.new(0)

    if EasyGantt.easy_attendances? && user.is_a?(User)
      attendaces = user.easy_attendances.non_working.between(from, to)
      attendaces.each do |attendace|
        nonworking_attendaces[attendace.arrival.to_date] += attendace.spent_time.to_f
      end
    end

    result = 0
    from.upto(to - 1.day).each do |date|
      next if weekend_cwdays.include?(date.cwday)
      next if working_calendar && working_calendar.holiday?(date)

      hours = max_hours_per_day - nonworking_attendaces[date]
      next if hours <= 0

      result += hours
    end
    result
  end

end
