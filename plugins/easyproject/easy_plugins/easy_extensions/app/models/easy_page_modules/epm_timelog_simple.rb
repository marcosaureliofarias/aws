class EpmTimelogSimple < EasyPageModule
  include EasyUtils::DateUtils

  def category_name
    @category_name ||= 'timelog'
  end

  def permissions
    @permissions ||= [:view_time_entries]
  end

  def get_show_data(settings, user, page_context = {})
    time_period = settings['time_period'] || '7_days'
    query       = EasyTimeEntryQuery.new(name: '_')
    query.add_filter('spent_on', 'date_period_1', { period: time_period, period_days: settings['time_period_days'] })

    if settings['output_type'].blank? || %w(list, table).include?(settings['output_type'])
      # entries = TimeEntry.visible.includes([:activity, :project, {:issue => [:tracker, :status, :priority]}]).references(:project, {:issue => :tracker})
      #   where(["#{TimeEntry.table_name}.user_id = ?", user.id]).spent_between(date_range[:from], date_range[:to]).order("#{TimeEntry.table_name}.spent_on DESC, #{Project.table_name}.name ASC, #{Tracker.table_name}.position ASC, #{Issue.table_name}.id ASC")
      query.add_filter('user_id', '=', [user.id.to_s])
      query.sort_criteria = { spent_on: 'desc', project: 'asc', tracker: 'asc', issue: 'asc' }
      query.column_names  = [:project, :tracker, :activity]

      entries        = query.entities
      entries_by_day = entries.group_by(&:spent_on)

      return { :entries_by_day => entries_by_day, :entries => entries, :period => time_period, :hours => entries.sum(&:hours) }
    elsif settings['output_type'] == 'chart'
      workers_ids = Array.wrap(settings['workers_ids']).collect { |w| w.gsub(/me/, user.id.to_s) }
      workers     = User.where(:id => workers_ids).sorted
      date_range  = get_date_range('1', time_period, '', '', settings['time_period_days'])

      if date_range[:to] && date_range[:to] > Date.today
        date_range[:to] = Date.today
        query.add_additional_statement(TimeEntry.arel_table[:spent_on].lteq(Date.today).to_sql)
      end

      query.add_filter('user_id', '=', workers_ids)
      query.group_by     = 'user'
      workers_spent_time = query.entity_sum_by_group(:hours)

      h = ActiveSupport::OrderedHash.new
      workers.each do |worker|
        h[worker] = [workers_spent_time[worker.id] || 0, worker.current_working_time_calendar.nil? ? 0 : worker.current_working_time_calendar.sum_working_hours(date_range[:from], date_range[:to])]
      end

      return { :workers => h, :hours => workers_spent_time.values.sum, :period => time_period }
    end
  end

end
