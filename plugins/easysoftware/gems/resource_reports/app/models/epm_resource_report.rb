# frozen_string_literal: true

class EpmResourceReport < EasyPageModule
  include EasyUtils::DateUtils

  DataItem = Struct.new(:allocations, :full_allocations, :all_spent_time, :capacity, :free_capacity, :allocations_percentage)

  def category_name
    'users'
  end

  def runtime_permissions(user)
    Rys::Feature.active?('resource_reports')
  end

  def default_settings
    @default_settings ||= {
      config: {
        period_zoom: 'month',
        period_name: 'current_year',
        period_type: '1',
        as_list: '1',
        show_capacity: '1',
        show_allocations: '1',
      }
    }.with_indifferent_access
  end

  def get_show_data(settings, user, **page_context)
    as_list = (settings.dig('config', 'output_type') == '1')
    as_chart = (settings.dig('config', 'output_type') == '2')

    show_capacity = (settings.dig('config', 'show_capacity') == '1')
    show_allocations = (settings.dig('config', 'show_allocations') == '1')
    # show_full_allocations       = (settings.dig('config', 'show_full_allocations') == '1')
    show_free_capacity = (settings.dig('config', 'show_free_capacity') == '1')
    show_all_spent_time = (settings.dig('config', 'show_all_spent_time') == '1')
    show_allocations_percentage = (settings.dig('config', 'show_allocations_percentage') == '1')

    show_settings = {
      capacity: show_capacity,
      allocations: show_allocations,
      # full_allocations: show_full_allocations,
      free_capacity: show_free_capacity,
      all_spent_time: show_all_spent_time,
      allocations_percentage: show_allocations_percentage,
    }

    principals = get_principals(settings, page_context: page_context)
    period_range = get_period_range(settings)
    zoom = settings.dig('config', 'period_zoom').presence || 'month'

    period_settings = EasyExtensions::EasyQueryHelpers::PeriodSetting.new(
      period_start_date: period_range[:from],
      period_end_date: period_range[:to],
      period_zoom: zoom,
    )

    all_periods = get_all_periods(period_settings)

    # { date => { user_id => DataItem } }
    data_items = Hash.new do |hash, date|
      hash[date] = Hash.new do |hash, user_id|
        hash[user_id] = DataItem.new
      end
    end

    # { date => DataItem }
    aggregated_items = Hash.new { |hash, date| hash[date] = DataItem.new }

    if show_allocations || show_free_capacity # || show_full_allocations
      load_allocations(settings: settings, data_items: data_items, period_range: period_range, principals: principals, zoom: zoom, page_context: page_context, period_settings: period_settings)
    end

    if show_all_spent_time || show_free_capacity
      load_all_spent_time(settings: settings, data_items: data_items, period_range: period_range, principals: principals, zoom: zoom)
    end

    if show_capacity || show_free_capacity || show_allocations_percentage
      load_capacity(data_items: data_items, principals: principals, all_periods: all_periods, period_settings: period_settings, period_range: period_range)
    end

    if show_free_capacity || show_allocations_percentage
      load_free_capacity(data_items: data_items, principals: principals, all_periods: all_periods)
    end

    if show_allocations_percentage
      load_allocations_percentage(data_items: data_items, principals: principals, all_periods: all_periods)
    end

    if show_capacity
      aggregate_items(aggregated_items: aggregated_items, data_items: data_items, key: 'capacity', type: 'sum')
    end

    if show_allocations
      aggregate_items(aggregated_items: aggregated_items, data_items: data_items, key: 'allocations', type: 'sum')
    end

    # if show_full_allocations
    #   aggregate_items(aggregated_items: aggregated_items, data_items: data_items, key: 'full_allocations', type: 'sum')
    # end

    if show_free_capacity
      aggregate_items(aggregated_items: aggregated_items, data_items: data_items, key: 'free_capacity', type: 'sum')
    end

    if show_all_spent_time
      aggregate_items(aggregated_items: aggregated_items, data_items: data_items, key: 'all_spent_time', type: 'sum')
    end

    if show_allocations_percentage
      aggregate_items(aggregated_items: aggregated_items, data_items: data_items, key: 'allocations_percentage', type: 'avg')
    end

    if as_chart
      chart_data = get_chart_data(data_items: data_items, principals: principals, all_periods: all_periods, zoom: zoom, show_settings: show_settings)
    end

    {
      data_items: data_items,
      principals: principals,
      zoom: zoom,
      period_range: period_range,
      all_periods: all_periods,
      as_list: as_list,
      as_chart: as_chart,
      chart_data: chart_data,
      show_settings: show_settings,
      aggregated_items: aggregated_items,
    }
  end

  def get_edit_data(settings, user, **page_context)
    user_query = EasyUserQuery.new
    user_query.from_params(settings['user_query'])

    group_query = EasyGroupQuery.new
    group_query.from_params(settings['group_query'])

    issue_query = EasyIssueQuery.new
    issue_query.from_params(settings['issue_query'])

    # Remove conflict filters
    issue_query.available_filters.delete('assigned_to_id')
    issue_query.available_filters.delete('member_of_group')
    issue_query.available_filters.delete('assigned_to_role')
    issue_query.available_filters.delete('allocated_dates')
    issue_query.available_filters.delete('allocated_hours')

    { user_query: user_query, issue_query: issue_query, group_query: group_query }
  end

  private

  def get_principals(settings, page_context:)
    user_query_params = settings['user_query'].presence
    group_query_params = settings['group_query'].presence

    add_additional_filters_from_global_filters!(page_context, user_query_params)
    add_additional_filters_from_global_filters!(page_context, group_query_params)

    user_query = EasyUserQuery.new
    user_query.from_params(user_query_params)

    group_query = EasyGroupQuery.new
    group_query.entity_scope = Group.visible.active.givable
    group_query.from_params(group_query_params)

    user_query.entities + group_query.entities
  end

  def get_period_range(settings)
    period_type = settings.dig('config', 'period_type').presence
    period_name = settings.dig('config', 'period_name').presence || 'current_year'
    period_from = settings.dig('config', 'period_from').presence
    period_to = settings.dig('config', 'period_to').presence

    # Period is range of two dates
    if period_type == '2' && period_from && period_to
      period_range = get_date_range('2', nil, period_from, period_to)
    else
      period_range = get_date_range('1', period_name)
    end

    # Because we cannot show endless table
    if period_range[:from].nil? && period_range[:to].nil?
      period_range = get_date_range('1', 'current_year')
    elsif period_range[:from].nil?
      period_range[:from] = period_range[:to] - 1.year
    elsif period_range[:to].nil?
      period_range[:to] = period_range[:from] + 1.year
    end

    period_range
  end

  def load_allocations(settings:, data_items:, period_range:, principals:, zoom:, page_context:, period_settings:)
    issue_query_params = settings['issue_query'].presence
    add_additional_filters_from_global_filters!(page_context, issue_query_params)

    principal_ids = principals.map { |p| p.id.to_s }

    issue_query = EasyIssueQuery.new
    issue_query.from_params(issue_query_params)
    issue_query.add_filter('assigned_to_id', '=', principal_ids)

    issue_ids = issue_query.create_entity_scope.ids

    # Because {date_condition} could return an Array
    # Non-sanitized Array cannot be used inside a pluck
    period_group_sql = Arel.sql(ActiveRecord::Base.sanitize_sql(issue_query.date_condition('easy_gantt_resources.date', zoom.to_sym)))

    # This is not relevant with an `issue_query` but the method is convenient
    date_range = issue_query.date_clause('easy_gantt_resources', 'date', period_range[:from], period_range[:to])

    resource_data = EasyGanttResource.where(issue_id: issue_ids, user_id: principal_ids).
      where(date_range).
      group(period_group_sql, 'easy_gantt_resources.user_id').
      pluck(
        period_group_sql,
        'easy_gantt_resources.user_id',
        Arel.sql('SUM(hours)'),
        Arel.sql('SUM(original_hours)'))

    resource_data.each do |(date_time, user_id, hours, original_hours)|
      data_items[date_time.to_date][user_id].tap do |item|
        item.allocations = hours
        # item.full_allocations = original_hours
      end
    end

    # load_reservations_into_full_allocations(settings: settings, data_items: data_items, period_range: period_range, principals: principals, zoom: zoom, page_context: page_context, period_settings: period_settings)
    load_easy_meetings_into_allocations(settings: settings, data_items: data_items, period_range: period_range, principals: principals, zoom: zoom, page_context: page_context, period_settings: period_settings)
    load_reservations_into_allocations(data_items: data_items, period_range: period_range, principals: principals, zoom: zoom)
  end

  def get_reservation_data(period_range:, principals:, zoom:)
    issue_query = EasyIssueQuery.new

    # Because {date_condition} could return an Array
    # Non-sanitized Array cannot be used inside a pluck
    period_group_sql = Arel.sql(ActiveRecord::Base.sanitize_sql(issue_query.date_condition('easy_gantt_reservation_resources.date', zoom.to_sym)))

    # This is not relevant with an `issue_query` but the method is convenient
    date_range = issue_query.date_clause('easy_gantt_reservation_resources', 'date', period_range[:from], period_range[:to])

    EasyGanttReservationResource.joins(:reservation).
      where(easy_gantt_reservations: { assigned_to_id: principals }).
      where(date_range).
      group(period_group_sql, 'easy_gantt_reservations.assigned_to_id').
      pluck(
        period_group_sql,
        'easy_gantt_reservations.assigned_to_id',
        Arel.sql('SUM(easy_gantt_reservation_resources.hours)'))
  end

  def load_reservations_into_allocations(data_items:, period_range:, principals:, zoom:)
    reservation_data = get_reservation_data(period_range: period_range, principals: principals, zoom: zoom)

    reservation_data.each do |(date_time, user_id, hours)|
      data_items[date_time.to_date][user_id].tap do |item|
        item.allocations ||= 0
        item.allocations += hours
      end
    end
  end

  # def load_reservations_into_full_allocations(settings:, data_items:, period_range:, principals:, zoom:, page_context:, period_settings:)
  #     reservation_data = get_reservation_data(period_range: period_range, principals: principals, zoom: zoom)
  #
  #     reservation_data.each do |(date_time, user_id, hours)|
  #       data_items[date_time.to_date][user_id].tap do |item|
  #         item.full_allocations ||= 0
  #         item.full_allocations += hours
  #       end
  #    end
  #
  #  end

  def load_easy_meetings_into_allocations(settings:, data_items:, period_range:, principals:, zoom:, page_context:, period_settings:)
    return if !Redmine::Plugin.installed?(:easy_calendar)

    invitations = EasyInvitation.includes(:easy_meeting).
      where(user_id: principals, accepted: [true, nil]).
      where(easy_meetings: { easy_resource_dont_allocate: [nil, false],
                             start_time: period_range[:from]..period_range[:to],
                             end_time: period_range[:from]..period_range[:to] })

    invitations.each do |invitation|
      meeting = invitation.easy_meeting

      start_date = User.current.user_time_in_zone(meeting.start_time).to_date
      end_date = User.current.user_time_in_zone(meeting.end_time).to_date

      multiple_day_meeting = (start_date != end_date)

      start_date.upto(end_date) do |date|
        hours =
          if multiple_day_meeting || meeting.all_day?
            EasyGanttResource.hours_on_week(invitation.user_id).fetch(date.cwday - 1, 0)
          else
            meeting.duration_hours
          end

        period_date = period_settings.beginning_of_period(date)

        data_items[period_date][invitation.user_id].allocations ||= 0
        data_items[period_date][invitation.user_id].allocations += hours
      end
    end
  end

  def load_all_spent_time(settings:, data_items:, period_range:, principals:, zoom:)
    query = EasyQuery.new
    principal_ids = principals.map { |p| p.id.to_s }

    # Because {date_condition} could return an Array
    # Non-sanitized Array cannot be used inside a pluck
    period_group_sql = Arel.sql(ActiveRecord::Base.sanitize_sql(query.date_condition('time_entries.spent_on', zoom.to_sym)))

    # This is not relevant with an `issue_query` but the method is convenient
    date_range = query.date_clause('time_entries', 'spent_on', period_range[:from], period_range[:to])

    spent_time_data = TimeEntry.where(user_id: principal_ids).
      where(date_range).
      group(period_group_sql, 'time_entries.user_id').
      pluck(
        period_group_sql,
        'time_entries.user_id',
        Arel.sql('SUM(hours)'))

    spent_time_data.each do |(date_time, user_id, hours)|
      data_items[date_time.to_date][user_id].all_spent_time = hours
    end
  end

  def get_all_periods(period_settings)
    all_periods = []
    current_period = period_settings.beginning_of_period
    end_of_period = period_settings.end_of_period

    while current_period <= end_of_period
      all_periods << current_period
      current_period += period_settings.zoom_shift(1)
    end

    all_periods
  end

  def load_capacity(data_items:, principals:, all_periods:, period_settings:, period_range:)
    principals.each do |principal|
      user_capacity = EasyGanttResource.hours_on_week(principal)

      all_periods.each do |period_date|
        current_capacity = 0

        range = period_settings.range_of_period(period_date)
        range.each do |date|
          current_capacity += user_capacity[date.cwday - 1]
        end

        data_items[period_date][principal.id].capacity = current_capacity
      end
    end

    load_holidays(data_items: data_items, principals: principals, all_periods: all_periods, period_settings: period_settings, period_range: period_range)
    load_attendaces(data_items: data_items, principals: principals, all_periods: all_periods, period_settings: period_settings, period_range: period_range)
  end

  def load_holidays(data_items:, principals:, all_periods:, period_settings:, period_range:)
    ResourceReports::Utils.groups_holidays(principals, from: period_range[:from], to: period_range[:to]) do |group_id, user_id, holiday, date, hours|
      period_date = period_settings.beginning_of_period(date)

      data_items[period_date][group_id].capacity -= hours
    end

    ResourceReports::Utils.users_holidays(principals, from: period_range[:from], to: period_range[:to]) do |user_id, holiday, date, hours|
      period_date = period_settings.beginning_of_period(date)

      data_items[period_date][user_id].capacity -= hours
    end
  end

  def load_attendaces(data_items:, principals:, all_periods:, period_settings:, period_range:)
    ResourceReports::Utils.groups_non_working_attendances(principals, from: period_range[:from], to: period_range[:to]) do |group_id, user_id, attendance, date, hours|
      period_date = period_settings.beginning_of_period(date)

      data_items[period_date][group_id].capacity -= hours
    end

    ResourceReports::Utils.users_non_working_attendances(principals, from: period_range[:from], to: period_range[:to]) do |user_id, attendance, date, hours|
      period_date = period_settings.beginning_of_period(date)

      # see {load_free_capacity}
      if attendance.time_entry
        data_items[period_date][user_id].free_capacity ||= 0
        data_items[period_date][user_id].free_capacity += attendance.time_entry.hours
      end

      data_items[period_date][user_id].capacity -= hours
    end
  end

  # Methods: {load_allocations}, {load_all_spent_time}, {load_capacity} must be called first
  def load_free_capacity(data_items:, principals:, all_periods:)
    principals.each do |principal|
      all_periods.each do |period_date|
        data_items[period_date][principal.id].tap do |item|
          # It must be `+=` and not `=`
          # Its a workaround for:
          #   user add holiday (attendance)
          #   if holiday is approved
          #   it also create a spent_time
          #   so the event will be calculated twice (item.capacity and item.all_spent_time)
          item.free_capacity ||= 0
          item.free_capacity += item.capacity.to_f - item.allocations.to_f - item.all_spent_time.to_f
        end
      end
    end
  end

  # Methods: {load_capacity}, {load_free_capacity} must be called first
  def load_allocations_percentage(data_items:, principals:, all_periods:)
    principals.each do |principal|
      all_periods.each do |period_date|
        data_items[period_date][principal.id].tap do |item|
          item.allocations_percentage = if item.free_capacity.to_f == 0
                                          item.capacity.to_f == 0 ? 0 : 100
                                        else
                                          100 * (1 - item.free_capacity.to_f / item.capacity.to_f)
                                        end
        end
      end
    end
  end

  # Transform
  #   { Date.new => { 1 => DataItem.new(capacity: 10, allocations: 20),
  #                   2 => DataItem.new(capacity: 30, allocations: 40) } }
  # into
  #   [ { name: FORMATED_DATE, "capacity__1" => 10, "capacity__2" => 30, ... } ]
  #
  def get_chart_data(data_items:, principals:, all_periods:, zoom:, show_settings:)
    chart_data = []

    all_periods.each do |period_date|
      period_name = ApplicationController.helpers.format_period(period_date, zoom.to_sym)

      add_item = lambda do |key|
        item = { 'name' => "#{period_name} - #{I18n.t("resource_reports.#{key}")}" }

        principals.each do |principal|
          item["principal_#{principal.id}"] = data_items[period_date][principal.id][key].to_f
        end

        chart_data << item
      end

      add_item.('capacity') if show_settings[:capacity]
      add_item.('allocations') if show_settings[:allocations]
      # add_item.('full_allocations') if show_settings[:full_allocations]
      add_item.('free_capacity') if show_settings[:free_capacity]
      add_item.('all_spent_time') if show_settings[:all_spent_time]
    end

    chart_data
  end

  def aggregate_items(aggregated_items:, data_items:, key:, type:)
    data_items.each do |period_date, principals_data|
      aggregated_items[period_date][key] ||= 0

      principals_data.each do |principal_id, data_item|
        aggregated_items[period_date][key] += data_item[key].to_f
      end

      if type == 'avg'
        aggregated_items[period_date][key] /= principals_data.size
      end
    end
  end

end
