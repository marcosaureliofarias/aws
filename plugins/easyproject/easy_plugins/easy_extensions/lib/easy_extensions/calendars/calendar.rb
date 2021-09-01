module EasyExtensions
  module Calendars

    class Calendar
      include Redmine::I18n

      attr_reader :startdt, :enddt, :period

      def initialize(date = Date.today, period = :month, lang = current_language)
        @date = date
        set_language_if_valid lang
        case period
        when :year
          @startdt = date.beginning_of_year
          @enddt   = @startdt.end_of_year
          @startdt = @startdt - (@startdt.cwday - first_wday) % 7
          # ends on the last day of the week
          @enddt = @enddt + (last_wday - @enddt.cwday) % 7
        when :month
          @startdt = Date.civil(date.year, date.month, 1)
          @enddt   = (@startdt >> 1) - 1
          # starts from the first day of the week
          @startdt = @startdt - (@startdt.cwday - first_wday) % 7
          # ends on the last day of the week
          @enddt = @enddt + (last_wday - @enddt.cwday) % 7
        when :week
          @startdt = date - (date.cwday - first_wday) % 7
          @enddt   = date + (last_wday - date.cwday) % 7
        else
          raise 'Invalid period'
        end
        @period = period
      end

      def self.first_wday
        case Setting.start_of_week.to_i
        when 1, 6, 7
          Setting.start_of_week.to_i
        else
          (I18n.t(:general_first_day_of_week).to_i - 1) % 7 + 1
        end
      end

      def self.last_wday
        (self.first_wday + 5) % 7 + 1
      end

      def month
        @date.month
      end

      def year
        @date.year
      end

      # Return the first day of week
      # 1 = Monday ... 7 = Sunday
      def first_wday
        @first_dow ||= self.class.first_wday
      end

      def last_wday
        @last_dow ||= self.class.last_wday
      end

      def next_start_date
        @enddt + 1.day
      end

      def prev_start_date
        case @period
        when :year
          @date - 1.year
        when :month
          @date - 1.month
        when :week
          @date - 1.week
        else
          @date
        end
      end

    end
  end
end
