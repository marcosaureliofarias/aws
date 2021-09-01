require 'easy_alerts/alert_rules'

module EasyAlerts
  module Rules

    class TimeEntryTimeWatcher < EasyAlerts::Rules::Base

      attr_accessor :period_from, :period_to, :hours

      validates :period_from, :presence => true
      validates :period_to, :presence => true
      validates_numericality_of :hours, :only_integer => true, :allow_nil => false

      def find_items(alert, user=nil)
        user ||= User.current
        
        pf, pt = self.period_from.split(':'), self.period_to.split(':')
        today_from = Time.local(Date.today.year, Date.today.month, Date.today.day, pf[0], pf[1])
        today_to = Time.local(Date.today.year, Date.today.month, Date.today.day, pt[0], pt[1])

        working_time_calendar = user.current_working_time_calendar if user.respond_to?(:current_working_time_calendar)

        if working_time_calendar.nil? && (Date.today.cwday == 6 || Date.today.cwday == 7)
          return nil
        elsif !working_time_calendar.nil? && !working_time_calendar.working_day?(Date.today)
          return nil
        end

        scope = TimeEntry.where(["user_id = ? AND spent_on = ? AND ((#{TimeEntry.table_name}.created_on BETWEEN ? AND ?) OR DATE(#{TimeEntry.table_name}.created_on) < spent_on)", user.id, Date.today, today_from, today_to])
        scope = scope.alerts_active_projects if active_projects_only
        sum = scope.sum(:hours)

        if sum < self.hours.to_f
          return user
        else
          return nil
        end
      end

      def serialize_settings_to_hash(params)
        s = super
        s[:period_from] = params['period_from'] if !params['period_from'].nil?
        s[:period_to] = params['period_to'] if !params['period_to'].nil?
        s[:hours] = params['hours'].to_i if !params['hours'].nil?
        s
      end

      def expires_at(alert)
        p = self.period_to.split(':')
        (Time.local(Date.today.year, Date.today.month, Date.today.day, p[0], p[1]) + 1.day).at_beginning_of_day
      end

      protected

      def initialize_properties(params)
        super
        @period_from = params[:period_from] unless params[:period_from].blank?
        @period_to = params[:period_to] unless params[:period_to].blank?
        @hours = params[:hours].to_i unless params[:hours].blank?
      end

    end

  end
end
