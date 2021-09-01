require 'easy_alerts/alert_rules'

module EasyAlerts
  module Rules

    class ProjectEstimatedHours < EasyAlerts::Rules::Base

      attr_accessor :percentage

      validates :percentage, :presence => true
      validates_numericality_of :percentage, :only_integer => true, :allow_nil => false

      def find_items(alert, user=nil)
        user ||= User.current
        
        founded_project = []
        scope = Project.visible(user)
        scope = scope.active if active_projects_only
        scope.all.each do |p|
          founded_project << p if p.percentage_of_time_spending >= self.percentage.to_i
        end

        return founded_project
      end

      def serialize_settings_to_hash(params)
        s = super
        s[:percentage] = params['percentage'] if !params['percentage'].nil?
        s
      end

      protected

      def initialize_properties(params)
        super
        @percentage = params[:percentage] unless params[:percentage].blank?
      end

    end

  end
end
