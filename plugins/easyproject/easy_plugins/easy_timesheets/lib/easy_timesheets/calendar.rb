module EasyTimesheets
  class Calendar < EasyExtensions::Calendars::Calendar
    attr_reader :user

    def initialize(date = Date.today, period = :week, lang = current_language, user = nil)
      @user = user || User.current
      if date.is_a?(String)
        date = begin; date.to_date; rescue; Date.today end
      end
      @date = date
      set_language_if_valid lang

      case period
      when :year
        @startdt  = date.beginning_of_year
        @enddt    = @startdt.end_of_year
        @startdt  = @startdt - (@startdt.cwday - first_wday)%7
        # ends on the last day of the week
        @enddt    = @enddt + (last_wday - @enddt.cwday)%7
      when :month
        @startdt = Date.civil(date.year, date.month, 1)
        @enddt = (@startdt >> 1)-1
      when :week
        @startdt = date - (date.cwday - first_wday)%7
        @enddt = date + (last_wday - date.cwday)%7
      else
        raise 'Invalid period'
      end
      @period = period
      # super(date, period, lang)
    end

    def self.first_wday(user=nil)
      user ||= User.current
      user && user.current_working_time_calendar.try(:first_day_of_week) || super()
    end

    def first_wday
      @first_dow ||= self.class.first_wday(@user)
    end

    def last_wday
      @user.current_working_time_calendar.last_wday
    end

    def working_day?(day)
      @user.current_working_time_calendar.working_day?(day)
    end

    def cell_css_classes(cell)
      css = []
      css << cell.time_entry&.easy_attendance&.easy_attendance_activity&.css_classes
      css << @user.current_working_time_calendar.css_classes(cell.spent_on.to_date)

      css.compact.join(' ')
    end

    def day_title(day)
      day = day.to_date
      if @user.current_working_time_calendar.holiday?(day)
        @user.current_working_time_calendar.holiday(day)&.name
      else
        day_name(day.cwday)
      end
    end
  end
end
