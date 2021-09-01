require 'easy_alerts/rules/helpers/projects_rule_helper'

module EasyAlerts
  module Rules

    class ProjectDueDate < EasyAlerts::Rules::DateBase
      include Helpers::ProjectsRuleHelper

      def find_items(alert, user=nil)
        user ||= User.current

        scope = ::Project.visible(user)
        scope = scope.where(["#{Project.table_name}.id IN (?)", self.projects]) unless self.projects.blank?
        scope = scope.active if active_projects_only

        if alert.rule_settings[:date_type] == 'date'
          unless self.get_date == Date.today
            scope = scope.none
          end
        else
          unless EasySetting.value('project_calculate_due_date')
            scope = scope.where(["#{Project.table_name}.easy_due_date = ?", self.get_date])
          end
        end

        unless EasySetting.value('project_calculate_due_date')
          scope.all
        else
          scope.all.select{|p| p.due_date && (p.due_date == self.get_date)}
        end
      end

    end

  end
end
