require 'easy_alerts/alert_rules'

module EasyAlerts
  module Rules

    class TimeEntryTimeWatcherPreviousPeriod < EasyAlerts::Rules::Base

      include EasyUtils::DateUtils

      attr_accessor :hours_type, :custom_hours, :time_period

      validate :validate_custom_hours

      def find_items(alert, user=nil)
        user ||= User.current

        working_time_calendar = user.current_working_time_calendar

        if self.time_period == 'day' || self.time_period.nil?
          yesterday = Date.today - 1.day

          if working_time_calendar.nil? && (yesterday.cwday == 6 || yesterday.cwday == 7)
            #return nil
          elsif !working_time_calendar.nil? && !working_time_calendar.working_day?(yesterday)
            return nil
          end

          scope = TimeEntry.where(:user_id => user.id, :spent_on => yesterday)
          scope = scope.alerts_active_projects if active_projects_only
          sum = scope.sum(:hours)
          if self.hours_type == 'calendar'
            working_hours = user.working_hours(yesterday) || 8.0
          end

        elsif self.time_period == 'week'
          week_range = get_date_range('1', 'last_week')

          scope = TimeEntry.where(:user_id => user.id, :spent_on => week_range[:from]..week_range[:to])
          scope = scope.alerts_active_projects if active_projects_only
          sum = scope.sum(:hours)
          if self.hours_type == 'calendar'
            working_hours = working_time_calendar.sum_working_hours(week_range[:from], week_range[:to]) || 40.0
          end
        end

        if self.hours_type == 'calendar' && sum < working_hours
          return user
        elsif self.hours_type == 'custom' && sum < self.custom_hours.to_f
          return user
        else
          return nil
        end
      end

      def serialize_settings_to_hash(params)
        s = super
        s[:hours_type] = params['hours_type'] if !params['hours_type'].nil?
        s[:custom_hours] = params['custom_hours'].to_f if !params['custom_hours'].nil?
        s[:time_period] = params['time_period'] if !params['time_period'].nil?
        s
      end

      def expires_at(alert)
        week_range = get_date_range('1', 'last_week')
        alert.rule_settings[:time_period] == 'week' ? (week_range[:from] + 14.days).to_time : (Time.now + 1.day).at_beginning_of_day
      end

      def mailer_template_name(alert)
        :alert_reports_timeentry_time_watcher_previous_period_for_group unless alert.mail_for == 'all'
      end

      protected

      def initialize_properties(params)
        super
        @hours_type = params[:hours_type] unless params[:hours_type].blank?
        @custom_hours = params[:custom_hours].to_f unless params[:custom_hours].blank?
        @time_period = params[:time_period] unless params[:time_period].blank?
      end

      private

      def validate_custom_hours
        errors.add :custom_hours, :blank if self.hours_type == 'custom' && self.custom_hours.blank?
      end

    end

  end
end
