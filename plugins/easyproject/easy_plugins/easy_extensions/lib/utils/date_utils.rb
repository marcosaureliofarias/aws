module EasyUtils
  module DateUtils
    include Redmine::I18n

    WEEKDAY_NUMBERS = {
        monday:    1,
        tuesday:   2,
        wednesday: 3,
        thursday:  4,
        friday:    5,
        saturday:  6,
        sunday:    7
    }

    # == Examples:
    #
    #   get_date_range('1', 'current_month')
    #   # => range for this month
    #
    #   get_date_range('1', 'current_month<<-1')
    #   # => range for previous month
    #
    #
    def get_date_range(period_type = '1', period = 'all', from = '', to = '', period_days = 0, period_days_from = '', period_days_to = '', shift = nil)
      @free_period  = false
      period_days   ||= 0
      start_of_week = EasyExtensions::Calendars::Calendar.first_wday

      ret   = { :from => nil, :to => nil }
      shift = shift.to_i if shift

      if period_type == '1' || (period_type.nil? && !period.nil?)

        if period.is_a?(String) && period.include?('<<')
          period, new_shift = period.split('<<')
          shift             ||= new_shift.to_i
        end

        case period
        when 'all', 'is_null', 'is_not_null'

        when 'to_now'
          ret[:from] = nil
          ret[:to]   = DateTime.now
        when 'today'
          ret[:from] = ret[:to] = Date.today
        when 'yesterday'
          ret[:from] = ret[:to] = Date.today - 1
        when 'current_week'
          ret[:from] = Date.today - (Date.today.cwday - start_of_week) % 7
          ret[:to]   = ret[:from] + 6
        when 'last_week'
          ret[:from] = Date.today - 7 - (Date.today.cwday - start_of_week) % 7
          ret[:to]   = ret[:from] + 6
        when 'last_2_weeks'
          ret[:from] = Date.today - 14 - (Date.today.cwday - start_of_week) % 7
          ret[:to]   = ret[:from] + 13
        when '7_days'
          ret[:from] = Date.today - 7
          ret[:to]   = Date.today
        when 'current_month'
          ret[:from] = Date.civil(Date.today.year, Date.today.month, 1)
          ret[:to]   = (ret[:from] >> 1) - 1
        when 'last30_next90'
          ret[:from] = Date.today - 30
          ret[:to]   = Date.today + 90
        when 'last_month'
          ret[:from] = Date.civil(Date.today.year, Date.today.month, 1) << 1
          ret[:to]   = (ret[:from] >> 1) - 1
        when '30_days'
          ret[:from] = Date.today - 30
          ret[:to]   = Date.today
        when '90_days'
          ret[:from] = Date.today - 90
          ret[:to]   = Date.today
        when 'current_year'
          ret[:from] = Date.civil(Date.today.year, 1, 1)
          ret[:to]   = Date.civil(Date.today.year, 12, 31)
        when 'last_year'
          ret[:from] = Date.civil(Date.today.year - 1, 1, 1)
          ret[:to]   = Date.civil(Date.today.year - 1, 12, 31)
        when 'older_than_14_days'
          ret[:from] = nil
          ret[:to]   = Date.today - 14
        when 'older_than_15_days'
          ret[:from] = nil
          ret[:to]   = Date.today - 15
        when 'older_than_31_days'
          ret[:from] = nil
          ret[:to]   = Date.today - 31
          ### FUTURE ###
        when 'tomorrow'
          ret[:from] = ret[:to] = Date.tomorrow
        when 'next_week'
          ret[:from] = Date.today + 7 - (Date.today.cwday - start_of_week) % 7
          ret[:to]   = ret[:from] + 6
        when 'next_5_days'
          ret[:from] = Date.today
          ret[:to]   = Date.today + 5
        when 'next_7_days'
          ret[:from] = Date.today
          ret[:to]   = Date.today + 7
        when 'next_10_days'
          ret[:from] = Date.today
          ret[:to]   = Date.today + 10
        when 'next_14_days'
          ret[:from] = Date.today
          ret[:to]   = Date.today + 14
        when 'next_15_days'
          ret[:from] = Date.today
          ret[:to]   = Date.today + 15
        when 'next_30_days'
          ret[:from] = Date.today
          ret[:to]   = Date.today + 30
        when 'next_90_days'
          ret[:from] = Date.today
          ret[:to]   = Date.today + 90
        when 'next_month'
          ret[:from] = Date.civil(Date.today.year, Date.today.month, 1) >> 1
          ret[:to]   = (ret[:from] >> 1) - 1
        when 'next_year'
          ret[:from] = Date.civil(Date.today.year + 1, 1, 1)
          ret[:to]   = Date.civil(Date.today.year + 1, 12, 31)
          ### EXTENDED ###
        when 'to_today'
          ret[:from] = nil
          ret[:to]   = Date.today
        when 'from_tomorrow'
          ret[:from] = Date.tomorrow
          ret[:to]   = nil
        when 'after_due_date'
          ret[:from] = nil
          ret[:to]   = Date.yesterday
          ### FISCAL ###
        when 'last_fiscal_year'
          ret[:from] = EasySetting.beginning_of_fiscal_year(Date.today - 1.year)
          ret[:to]   = EasySetting.end_of_fiscal_year(Date.today - 1.year)
        when 'current_fiscal_year'
          ret[:from] = EasySetting.beginning_of_fiscal_year
          ret[:to]   = EasySetting.end_of_fiscal_year
        when 'next_fiscal_year'
          ret[:from] = EasySetting.beginning_of_fiscal_year(Date.today + 1.year)
          ret[:to]   = EasySetting.end_of_fiscal_year(Date.today + 1.year)
        when 'last_fiscal_quarter'
          ret = EasyUtils::DateUtils.calculate_fiscal_quarter(Date.today - 3.months)
        when 'current_fiscal_quarter'
          ret = EasyUtils::DateUtils.calculate_fiscal_quarter
        when 'next_fiscal_quarter'
          ret = EasyUtils::DateUtils.calculate_fiscal_quarter(Date.today + 3.months)
        when 'in_less_than_n_days' # <t+
          ret[:from] = nil
          ret[:to]   = Date.today + period_days.to_i.days
        when 'in_more_than_n_days' # >t+
          ret[:from] = Date.today + period_days.to_i.days
          ret[:to]   = nil
        when 'in_next_n_days' # ><t+
          ret[:from] = Date.today
          ret[:to]   = Date.today + period_days.to_i.days
        when 'in_n_days' # t+
          ret[:from] = ret[:to] = Date.today + period_days.to_i.days
        when 'less_than_ago_n_days' # >t-
          ret[:from] = Date.today - period_days.to_i.days
          ret[:to]   = nil
        when 'more_than_ago_n_days' # <t-
          ret[:from] = nil
          ret[:to]   = Date.today - period_days.to_i.days
        when 'in_past_n_days' # ><t-
          ret[:from] = Date.today - period_days.to_i.days
          ret[:to]   = Date.today
        when 'ago_n_days' # t-
          ret[:from] = ret[:to] = Date.today - period_days.to_i.days
        when 'from_m_to_n_days'
          ret[:from] = Date.today - period_days_from.to_i.days
          ret[:to]   = Date.today + period_days_to.to_i.days
        else
          if respond_to?("hook_#{period}")
            ret = send("hook_#{period}")
          else
            Rails.logger.warn "You must add '#{period}' to 'utils/dateutils' !" if Rails.logger
          end
        end

        if shift && ret[:from] && ret[:to]
          case period
          when 'current_month', 'last_month', 'next_month'
            ret[:from] = ret[:from].advance(months: shift)
            ret[:to]   = ret[:to].advance(months: shift)
          when 'last_fiscal_quarter', 'current_fiscal_quarter', 'next_fiscal_quarter'
            ret[:from] = ret[:from].advance(months: (3 * shift))
            ret[:to]   = ret[:to].advance(months: (3 * shift))
          when 'current_year', 'last_year', 'next_year', 'last_fiscal_year', 'current_fiscal_year', 'next_fiscal_year'
            ret[:from] = ret[:from].advance(years: shift)
            ret[:to]   = ret[:to].advance(years: shift)
          else
            range_shift = (ret[:to] - ret[:from]) * shift
            ret[:from]  = ret[:from].advance(days: range_shift)
            ret[:to]    = ret[:to].advance(days: range_shift)
          end
        end
      elsif period_type == '2' || (period_type.nil? && (!from.nil? || !to.nil?))
        begin
          ret[:from] = from.to_s.to_date unless from.blank?
        rescue
        end
        begin
          ret[:to] = to.to_s.to_date unless to.blank?
        rescue
        end

        if shift && ret[:from] && ret[:to]
          range_shift = (ret[:to] - ret[:from]) * shift
          ret[:from]  = ret[:from].advance(days: range_shift)
          ret[:to]    = ret[:to].advance(days: range_shift)
        end

        @free_period = true
      end

      ret[:from], ret[:to] = ret[:to], ret[:from] if ret[:from] && ret[:to] && ret[:from] > ret[:to]
      return ret
    end

    def self.calculate_from_period_options(date = nil, period_options = {})
      return nil if period_options.blank?
      date ||= Date.today

      if period_options['time'] == 'defined' && !period_options['hours'].blank?
        hour, minute = period_options['hours'].split(':')
      else
        hour, minute = nil, nil
      end

      # find out whether the notification should be sent today or not
      today_time_in_future = Time.local(date.year, date.month, date.day, hour, minute) > Time.now

      case period_options['period']
      when 'days_in_week'
        selected_days = Array(period_options['days_in_week']).collect(&:to_i).sort

        if no_day = selected_days.detect { |n| n.to_i > date.cwday || (today_time_in_future && n.to_i == date.cwday) }
          next_date = date + (no_day - date.cwday).days
        elsif no_day = selected_days.detect { |n| n.to_i < date.cwday || (!today_time_in_future && n.to_i == date.cwday) }
          next_date = date - (date.cwday - no_day).days + 7.days
        end

        next_date ||= today_time_in_future ? date : date + 1.day
      when 'days_in_month'
        selected_days = Array(period_options['days_in_month']).collect(&:to_i).sort

        no_day = selected_days.detect { |n| n.to_i > date.day || (today_time_in_future && n.to_i == date.day) }
        no_day ||= selected_days.detect { |n| n.to_i < date.day || (!today_time_in_future && n.to_i == date.day) }
        no_day ||= today_time_in_future ? date.day : date.day + 1.day # if no day is selected -> execute everyday

        if no_day < date.day || (!today_time_in_future && no_day == date.day)
          date = date.advance(months: 1)
        end
        next_date = new_date(date.year, date.month, no_day)
      else
        next_date ||= today_time_in_future ? date : date + 1.day
      end

      Time.local(next_date.year, next_date.month, next_date.day, hour, minute)
    end

    def self.build_datetime_from_params(value)
      case value
      when Hash
        date = begin
          value[:date].to_date
        rescue
        end
        if date
          if value[:time].is_a?(Hash)
            time = [value[:time][:hour], value[:time][:minute]]
          elsif value[:time].present? &&
              value[:time].match(/^([0-1]?[0-9]|2[0-3])([:\-,\.])?([0-5][0-9])$/)

            # valid inputs: 09:30, 9:30, 0930, 930, 9,30, 9.30, 9-30
            # invalid inputs: 24:00, 09:60
            time = [$1, $3]
          elsif value[:hour] || value[:minute]
            time = value[:hour], value[:minute]
          else
            time = 0, 0
          end

          if User.current.time_zone
            Time.use_zone(User.current.time_zone) do
              Time.zone.local(date.year, date.month, date.day, time[0].to_i, time[1].to_i)
            end
          else
            Time.local(date.year, date.month, date.day, time[0].to_i, time[1].to_i)
          end
        end
      when Time, Date
        value.to_time
      else
        datetime = begin
          DateTime.parse(value)
        rescue
        end
        if datetime
          self.build_datetime_from_params({ :date => datetime.to_date, :hour => datetime.hour, :minute => datetime.minute })
        end
      end
    end

    def self.time_as_date?(time)
      !!(time && (time.beginning_of_day == time))
    end

    def self.new_date(year, month, day)
      begin
        Date.new(year, month, day)
      rescue
        Date.new(year, month, 1).end_of_month
      end
    end

    def self.calculate_fiscal_quarter(date = nil)
      date  ||= Date.today
      shift = EasySetting.value('fiscal_month').nil? ? 0 : ((EasySetting.value('fiscal_month').to_i - 1) % 3)

      beginning_current_quarter = date.beginning_of_quarter
      end_current_quarter       = date.end_of_quarter
      beginning_shifted_quarter = beginning_current_quarter.advance(months: shift)
      end_shifted_quarter       = end_current_quarter.advance(months: shift).end_of_month
      if date.between?(beginning_shifted_quarter, end_shifted_quarter)
        { from: beginning_shifted_quarter, to: end_shifted_quarter }
      else
        beginning_prev_quarter = beginning_current_quarter.advance(months: (shift - 3))
        end_prev_quarter       = end_current_quarter.advance(months: (shift - 3))
        { from: beginning_prev_quarter, to: end_prev_quarter.end_of_month }
      end

      # active_support/core_ext/date_and_time/calculations.rb:88
      # first_quarter_month = [10, 7, 4, 1].map { |i| i + shift }.detect { |m| m <= date.month }
      # quarter_start = date.beginning_of_month.change(month: first_quarter_month)
      #
      # last_quarter_month = [3, 6, 9, 12].map { |i| i + shift }.detect { |m| m >= date.month }
      # quarter_end = date.beginning_of_month.change(month: last_quarter_month % 12 == 0 ? 12 : last_quarter_month % 12).end_of_month
      #
      # quarter_end += 1.year if last_quarter_month > 12
      #
      # {from: quarter_start, to: quarter_end}
    end

    def self.day_of_week_start
      WEEKDAY_NUMBERS.key((Setting.start_of_week.presence || I18n.t(:general_first_day_of_week, default: '1')).to_i)
    end

    def self.from_name(name)
      if !name.is_a?(String)
        return nil
      end

      case name
      when 'today'
        Date.today
      when '7_days_ago'
        Date.today - 7
      end
    end

  end
end
