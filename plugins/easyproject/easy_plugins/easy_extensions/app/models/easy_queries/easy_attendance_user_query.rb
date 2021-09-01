class AttendancePeriodSetGeneratedColumn < EasyQueryPeriodGeneratedColumn
  attr_accessor :cumulative

  def initialize(period_column, options = {})
    super(period_column, period_column.options.merge(options))
    @cumulative  = options[:cumulative]
    @entity_type = options[:entity_type]
    if @entity_type.present? && @entity_type[:entity].nil? && @query
      @calculation_column = true
      @positive_column    = @query.get_generated_column(@entity_type[:positive], @period_idx)
      @negative_column    = @query.get_generated_column(@entity_type[:negative], @period_idx)
      @denominator_column = @query.get_generated_column(@entity_type[:denominator], @period_idx)
    end
  end

  def value(entity, options = {})
    if @calculation_column
      result = 0
      result += @positive_column.value(entity, options).to_f if @positive_column
      result -= @negative_column.value(entity, options).to_f if @negative_column
      result /= @denominator_column.value(entity, options).to_f if @denominator_column
      result
    else
      result = @query.column_values(entity, @entity_type, @query.beginning_of_period_zoom(@start_date), @end_date, options.merge(cumulative: @cumulative, with_history: @with_history))
    end
    set_css(entity, name, result)
    result
  end

  def set_css(entity, name, value)
    @entity_css = entity.attribute_css_classes(name, value)
  end

  def css_classes
    super + @entity_css.to_s
  end
end

class AttendancePeriodSetColumn < EasyQueryPeriodColumn

  attr_accessor :options, :entity_type

  def initialize(name, options = {})
    @entity_type = options[:entity_type] || {}
    @options     = options.dup
    super(name, options)
  end

  def visible?
    false
  end

  def generate(idx, query)
    AttendancePeriodSetGeneratedColumn.new(self, :period_idx => idx, :query => query, with_history: options[:with_history], entity_type: options[:entity_type], cumulative: options[:cumulative])
  end

end

class AttendanceParameterizedColumn < EasyQueryParameterizedColumn
  def value(entity, options = {})
    val = super(entity, options)
    set_css(entity, name, val)
    val
  end

  def set_css(entity, name, value)
    @entity_css = entity.attribute_css_classes(name, value)
  end

  def css_classes
    super + @entity_css.to_s
  end
end

class EasyAttendanceUserQuery < EasyUserQuery

  def generated_period_columns
    return [] unless period_columns?
    @generated_period_columns ||= 0.upto(number_of_periods_by_zoom - 1).map do |period_idx|
      period_columns.map do |period_column|
        period_column.generate(period_idx, self)
      end
    end.flatten
  end

  def get_values(klass)
    @values_tables ||= {}
    return @values_tables[klass] if @values_tables[klass]
    scope = scope_for_calculations(create_entity_scope({ skip_order: true }))
    case klass
    when 'easy_attendance'
      @values_tables[klass] ||= self.class.connection.select_all(
          scope.joins(easy_attendances: :easy_attendance_activity)
              .where(easy_attendances: { easy_attendance_activity_id: selected_easy_attendance_activity_ids_from_columns })
              .where(["#{EasyAttendanceActivity.table_name}.approval_required = ? OR approval_status = ?", false, EasyAttendance::APPROVAL_APPROVED])
              .where("#{EasyAttendance.table_name}.arrival >= ?", period_start_date)
              .group(sql_for_group_from_columns)
              .select(sql_for_select_from_columns + ',' + aggregation_from_columns)
              .to_sql).to_a
    when 'time_entry'
      @values_tables[klass] ||= self.class.connection.select_all(
          scope.joins(time_entries: [:project, :activity])
              .where(["#{Project.table_name}.easy_is_easy_template = ?", false])
              .where("#{TimeEntry.table_name}.spent_on >= ?", period_start_date)
              .group(sql_for_group_from_columns_for_time_entry)
              .select(sql_for_select_from_columns_for_time_entry + ',' + aggregation_from_columns_for_time_entry)
              .to_sql).to_a
    else
      []
    end
  end

  def column_values(entity, entity_type, start_date, end_date, options)
    default = 0.0
    if entity_type[:positive].is_a?(Hash) && entity.respond_to?(entity_type[:positive][:method].to_s)
      positive_default = entity.send(entity_type[:positive][:method].to_s, entity_type[:positive][:options].merge(date: start_date.advance(days: 1), query: self, entity: entity))
      return nil if positive_default.nil?
      default += positive_default
    end
    if entity_type[:negative].is_a?(Hash) && entity.respond_to?(entity_type[:negative][:method].to_s)
      negative_default = entity.send(entity_type[:negative][:method].to_s, entity_type[:negative][:options].merge(date: start_date.advance(days: 1), query: self, entity: entity))
      return nil if negative_default.nil?
      default -= negative_default
    end

    calculation = { until_period_start: default, in_the_period: default, until_period_end: default }
    end_date    = start_date.end_of_year if start_date.year != end_date.year && period_zoom.to_s == 'week'
    get_values(entity_type[:entity]).each do |user_data|
      activity_id = user_data['activity_id'].to_i
      positive    = 1 if entity_type[:positive].is_a?(Array) && entity_type[:positive].include?(activity_id)
      positive    = -1 if entity_type[:negative].is_a?(Array) && entity_type[:negative].include?(activity_id)
      score_record(positive, user_data, entity, start_date, end_date, calculation) unless positive.nil?
    end
    if options[:cumulative]
      return calculation[:until_period_end]
    elsif period_zoom.to_s.in?(['day', 'week', 'month'])
      return calculation[:in_the_period]
    else
      return calculation[:until_period_end] - calculation[:until_period_start]
    end
  end

  def score_record(sign, record, entity, start_date, end_date, options)
    return unless entity.id == record['id'].to_i
    year   = record['year'].to_i
    period = record['period'].to_i
    sum    = record['sum'].to_f
    if year <= start_date.year && (record['period'] ? period <= date_to_idx(start_date) || start_date.year != year : true)
      options[:until_period_start] += sign * sum
    end
    if year == end_date.year && (record['period'] ? period == date_to_idx(end_date) : true)
      options[:in_the_period] += sign * sum
    end
    if year <= end_date.year && (record['period'] ? period <= date_to_idx(end_date) || end_date.year != year : true)
      options[:until_period_end] += sign * sum
    end
  end

  def period_columns?
    true
  end

  def sql_for_group_from_columns
    "#{User.table_name}.id, #{EasyAttendance.table_name}.easy_attendance_activity_id, #{entity.send(:sanitize_sql_array, date_condition('arrival', :year_short))}, #{entity.send(:sanitize_sql_array, date_condition('arrival', sql_period))}"
  end

  def sql_for_select_from_columns
    "#{User.table_name}.id, #{EasyAttendance.table_name}.easy_attendance_activity_id as activity_id, #{entity.send(:sanitize_sql_array, date_condition('arrival', :year_short))} as year, #{entity.send(:sanitize_sql_array, date_condition('arrival', sql_period))} as period"
  end

  def sql_for_group_from_columns_for_time_entry
    spent_on = "#{TimeEntry.table_name}.spent_on"
    "#{User.table_name}.id, #{TimeEntry.table_name}.activity_id, #{entity.send(:sanitize_sql_array, date_condition(spent_on, :year_short))}, #{entity.send(:sanitize_sql_array, date_condition(spent_on, sql_period))}"
  end

  def sql_for_select_from_columns_for_time_entry
    spent_on = "#{TimeEntry.table_name}.spent_on"
    "#{User.table_name}.id, #{TimeEntry.table_name}.activity_id, #{entity.send(:sanitize_sql_array, date_condition(spent_on, :year_short))} as year, #{entity.send(:sanitize_sql_array, date_condition(spent_on, sql_period))} as period"
  end

  def selected_easy_attendance_activity_ids_from_columns
    ids = []
    aggregated_set_columns.each do |column|
      entity_type = column.entity_type
      if entity_type[:entity] == 'easy_attendance'
        ids |= entity_type[:positive] if entity_type[:positive].is_a?(Array)
        ids |= entity_type[:negative] if entity_type[:negative].is_a?(Array)
      end
    end
    ids.empty? ? EasyAttendanceActivity.ids : ids
  end

  def aggregation_from_columns
    "SUM(#{self.sql_time_diff('arrival', 'departure')}) as sum"
  end

  def aggregation_from_columns_for_time_entry
    "SUM(#{TimeEntry.table_name}.hours) as sum"
  end

  def available_filters
    unless @available_filters_added_easy_attendance_user
      super

      on_filter_group(l(:label_filter_group_easy_user_query)) do
        if User.current.allowed_to_globally?(:view_easy_attendance_other_users)
          add_principal_autocomplete_filter 'user_id', { klass: User, source_options: { internal_non_system: true } }
        end
      end

      @available_filters_added_easy_attendance_user = true
    end

    @available_filters
  end

  def available_columns
    return @available_columns_added2 if @available_columns_added2
    @available_columns_added2 = super
    eaa_entities              = EasyAttendanceActivity.sorted
    eaa_with_limits           = EasyAttendanceActivity.joins(:easy_attendance_activity_user_limits).sorted.distinct
    ta_entities               = TimeEntryActivity.sorted
    group_time_entry          = l(:label_filter_group_easy_time_entry_query)
    group_ratios              = l(:label_filter_group_easy_report_ratios)
    attendance_group          = l(:label_filter_group_easy_attendance_query)
    attendance_columns        = eaa_entities.map { |attendance_activity| AttendancePeriodSetColumn.new('eaa_sum_' + attendance_activity.id.to_s, title: attendance_activity.name, sumable: true, sumable_sql: false, entity_type: { positive: [attendance_activity.id], negative: [], entity: 'easy_attendance' }, group: attendance_group) }
    attendance_columns << AttendancePeriodSetColumn.new('eaa_sum_all', title: l(:label_easy_attendance_sum), sumable: true, sumable_sql: false, entity_type: { positive: eaa_entities.map(&:id), negative: [], entity: 'easy_attendance' }, group: attendance_group)
    attendance_columns += ta_entities.map { |attendance_activity| AttendancePeriodSetColumn.new('ta_sum_' + attendance_activity.id.to_s, title: attendance_activity.name, sumable: true, sumable_sql: false, entity_type: { positive: [attendance_activity.id], negative: [], entity: 'time_entry' }, group: group_time_entry) }
    attendance_columns += eaa_with_limits.map { |attendance_activity| AttendanceParameterizedColumn.new('eaa_limit_this_year_' + attendance_activity.id.to_s, arguments: attendance_activity.id, :method => 'get_user_attendance_limit', title: l('label_easy_attendance_limit_this_year', name: attendance_activity.name), sumable: true, sumable_sql: false, group: attendance_group) }
    attendance_columns += eaa_with_limits.map { |attendance_activity| AttendanceParameterizedColumn.new('eaa_limit_accumulated_' + attendance_activity.id.to_s, arguments: attendance_activity.id, :method => 'get_user_attendance_accumulated', title: l('label_easy_attendance_limit_accumulated', name: attendance_activity.name), sumable: true, sumable_sql: false, group: attendance_group) }
    attendance_columns += eaa_with_limits.map { |attendance_activity| AttendanceParameterizedColumn.new('eaa_remaining_limit_' + attendance_activity.id.to_s, arguments: [attendance_activity, { query: self }], :method => 'get_user_attendance_remaining', title: l('label_easy_attendance_remaining_limit', name: attendance_activity.name), sumable: true, sumable_sql: false, group: attendance_group) }
    attendance_columns += eaa_with_limits.map { |attendance_activity| AttendanceParameterizedColumn.new('eaa_year_sum_' + attendance_activity.id.to_s, arguments: [attendance_activity, { query: self }], :method => 'get_user_attendance_year_sum', title: l('label_easy_attendance_year_sum', name: attendance_activity.name), sumable: true, sumable_sql: false, group: attendance_group) }
    attendance_columns << AttendancePeriodSetColumn.new('time_entry_in_period', title: l(:label_easy_attendance_spent_time), sumable: true, sumable_sql: false, entity_type: { positive: ta_entities.map(&:id), negative: [], entity: 'time_entry' }, group: group_time_entry)
    attendance_columns << AttendancePeriodSetColumn.new('time_entry_in_period_diff_working_time_percent', title: l(:label_easy_attendance_spent_time_diff_working_time_percent), entity_type: { positive: :time_entry_in_period, denominator: :periodic_work_time }, group: group_ratios, preload: { working_time_calendar: [:exceptions, :parent_exceptions, :holidays, :parent_holidays] })
    attendance_columns << AttendancePeriodSetColumn.new('time_entry_in_period_diff_working_time', title: l(:label_easy_attendance_spent_time_diff_working_time), sumable: true, sumable_sql: false, entity_type: { positive: :time_entry_in_period, negative: :periodic_work_time }, group: group_ratios, preload: { working_time_calendar: [:exceptions, :parent_exceptions, :holidays, :parent_holidays] })
    attendance_columns << AttendancePeriodSetColumn.new('working_attendance_percent', title: l(:label_easy_attendance_working_attendance_percent), entity_type: { positive: :time_entry_in_period, denominator: :eaa_sum_all }, group: group_ratios)
    attendance_columns << AttendancePeriodSetColumn.new('working_attendance', title: l(:label_easy_attendance_working_attendance), sumable: true, sumable_sql: false, entity_type: { positive: :time_entry_in_period, negative: :eaa_sum_all }, group: group_ratios)
    attendance_columns << AttendancePeriodSetColumn.new('attendance_in_period_diff_working_time_percent', title: l(:label_easy_attendance_attendence_diff_working_time_percent), entity_type: { positive: :eaa_sum_all, denominator: :periodic_work_time }, group: group_ratios, preload: { working_time_calendar: [:exceptions, :parent_exceptions, :holidays, :parent_holidays] })
    attendance_columns << AttendancePeriodSetColumn.new('attendance_in_period_diff_working_time', title: l(:label_easy_attendance_attendence_diff_working_time), sumable: true, sumable_sql: false, entity_type: { positive: :eaa_sum_all, negative: :periodic_work_time }, group: group_ratios, preload: { working_time_calendar: [:exceptions, :parent_exceptions, :holidays, :parent_holidays] })
    attendance_columns << EasyQueryPeriodColumn.new('cumulative_work_time_this_year', title: l(:label_easy_attendance_work_time_cum), sumable: true, sumable_sql: false)
    attendance_columns << EasyQueryPeriodColumn.new('periodic_work_time', title: l(:label_easy_attendance_work_time_periodic), sumable: true, sumable_sql: false, preload: { working_time_calendar: :exceptions })
    @available_columns_added2.concat(attendance_columns)
    @available_columns_added2
  end

  def aggregated_set_columns
    @aggregated_set_columns ||= columns.select { |c| c.is_a?(AttendancePeriodSetColumn) }
  end

  def date_to_idx(date)
    case self.period_zoom.to_s
    when 'day'
      date.yday
    when 'week'
      date.cweek
    else
      date.month
    end
  end

  def sql_period
    case self.period_zoom.to_s
    when 'day'
      :day_of_year
    when 'week'
      :cweek
    else
      :month_of_year
    end
  end

  def self.permission_view_entities
  end

  def query_after_initialize
    super
    self.display_project_column_if_project_missing = false
    export                                         = ActiveSupport::OrderedHash.new
    export[:xlsx]                                  = {}
    self.export_formats                            = export
    self.display_filter_fullscreen_button          = false
    self.display_filter_sort_on_index              = false
    self.display_filter_group_by_on_edit           = true
  end

  def entity_scope
    User.logged.visible.non_system_flag.easy_type_internal
  end

  def entity_easy_query_path(options)
    detailed_report_easy_attendances_path(options.merge(tab: 'detailed_report'))
  end

  def default_columns
    @default_columns ||= EasyAttendanceActivity.group(:at_work).order(Arel.sql('MIN(position)')).minimum(:id).values.map { |id| "eaa_sum_#{id}" }
  end

  def default_list_columns
    super.presence || ['firstname', 'lastname'] + default_columns
  end

  def sql_for_user_id_field(field, operator, value)
    sql_for_field(field, operator, value, entity_table_name, 'id')
  end

  def self.list_support?
    false
  end

  def self.report_support?
    false
  end

end
