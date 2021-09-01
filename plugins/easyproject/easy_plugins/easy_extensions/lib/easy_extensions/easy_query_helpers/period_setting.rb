module EasyExtensions
  module EasyQueryHelpers
    class PeriodSetting < Hash

      ALL_PERIODS = ['day', 'week', 'month', 'quarter', 'year']

      def initialize(values = {})
        super()
        self.merge!(values)
      end

      def all_periods
        ALL_PERIODS
      end

      def zoom
        self[:period_zoom] || 'month'
      end

      def start_date
        self[:period_start_date] || beginning_of_period(EasySetting.beginning_of_fiscal_year)
      end

      def end_date
        self[:period_end_date] || end_of_period(start_date + zoom_shift(number_of_periods_by_zoom - 1))
      end

      def zoom=(value)
        self[:period_zoom] = value if value
      end

      def start_date=(value)
        self[:period_start_date] = value.to_date if value
      rescue ArgumentError
      end

      def end_date=(value)
        self[:period_end_date] = value.to_date if value
      rescue ArgumentError
      end

      def number_of_periods_by_zoom
        period_start_date      = self[:period_start_date] ? beginning_of_period(self[:period_start_date]) : nil
        period_end_date        = self[:period_end_date] ? end_of_period(self[:period_end_date]) : nil
        period_date_difference = (period_end_date && period_start_date) ? (period_end_date - period_start_date) + 1 : nil
        periods                = case self.zoom.to_s
                                 when 'day'
                                   period_date_difference ? period_date_difference : 31
                                 when 'week'
                                   period_date_difference ? (period_date_difference / 7.0).ceil : 14
                                 when 'month'
                                   period_date_difference ? period_end_date.month - start_date.month + 1 + (period_end_date.year - start_date.year) * 12 : 12
                                 when 'quarter'
                                   period_date_difference ? ((period_end_date.month - start_date.month + 1 + (period_end_date.year - start_date.year) * 12) / 3.0).ceil : 4
                                 when 'year'
                                   period_date_difference ? ((period_end_date.month - start_date.month + 1 + (period_end_date.year - start_date.year) * 12) / 12.0).ceil : 4
                                 end
        max_periods            = (EasySetting.value('easy_query_max_periods') || 31).to_i
        periods > max_periods ? max_periods : periods
      end

      def set_current_period(date = nil)
        date            ||= Date.today
        self.start_date = beginning_of_period(date)
        self.end_date   = end_of_period(date)
      end

      def beginning_of_period(date = nil, zoom = nil)
        date ||= self.start_date

        case zoom || self.zoom.to_s
        when 'day'
          date
        when 'week'
          date.beginning_of_week(EasyUtils::DateUtils.day_of_week_start)
        when 'month'
          date.beginning_of_month
        when 'quarter'
          EasyUtils::DateUtils.calculate_fiscal_quarter(date.try(:to_date))[:from]
        when 'year'
          date.beginning_of_year
        end
      end

      def end_of_period(date = nil, zoom = nil)
        date ||= self.end_date

        case zoom || self.zoom.to_s
        when 'day'
          date
        when 'week'
          date.end_of_week(EasyUtils::DateUtils.day_of_week_start)
        when 'month'
          date.end_of_month
        when 'quarter'
          EasyUtils::DateUtils.calculate_fiscal_quarter(date.try(:to_date))[:to]
        when 'year'
          date.end_of_year
        end
      end

      def range_of_period(date = nil, zoom = nil)
        beginning_of_period(date, zoom)..end_of_period(date, zoom)
      end

      def zoom_shift(period_count)
        case self.zoom.to_s
        when 'day'
          period_count.day
        when 'week'
          period_count.week
        when 'month'
          period_count.month
        when 'quarter'
          (period_count * 3).month
        when 'year'
          period_count.year
        end
      end

      # simplified version: acts_as_easy_translate manipulates with hash_with_indifferent_access, which converts all
      # values which satisfy condition 'value.is_a? Hash' to HashWithIndifferentAccess and PeriodSetting < Hash
      def nested_under_indifferent_access
        self
      end

    end
  end
end
