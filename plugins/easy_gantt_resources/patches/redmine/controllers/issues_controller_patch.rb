module EasyGanttResources
  module IssuesControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        before_action :gantt_resources_messages, only: [:show]
      end
    end

    module InstanceMethods

      def gantt_resources_messages
        return unless request.format.html?
        return unless @issue.assigned_to.is_a?(User)
        return unless EasySetting.value(:easy_gantt_resources_watchdog_enabled, @issue.project_id)
        return if !User.current.allowed_to_globally?(:edit_global_easy_gantt) ||
                  !User.current.allowed_to_globally?(:view_global_easy_gantt)

        dates = @issue.easy_gantt_resources.where('hours > 0').pluck(:date)
        return if dates.empty?

        resources = EasyGanttResource.where(user_id: @issue.assigned_to, date: dates).
                                      group(:date).
                                      sum(:hours).
                                      sort_by{|(date, _)| date }
        return if resources.empty?

        max_hours_on_week = EasyGanttResource.hours_on_week(@issue.assigned_to)

        errors = []
        resources.each do |date, hours|
          hours_on_day = max_hours_on_week[date.cwday-1]

          if hours > hours_on_day
            errors << "#{date} (+#{hours - hours_on_day})"

            # Too much informations
            if errors.size > 5
              errors << '...'
              break
            end
          end
        end

        link = easy_gantt_resources_path(
          set_filter: '1',
          period: dates.minmax.join('|'),
          user_id: "=#{@issue.assigned_to_id}",
          group_id: '=0',
          issue_status_id: 'o1',
          open_user_id: @issue.assigned_to_id
        )

        if errors.any?
          flash.now[:error] = l(:text_easy_gantt_resources_overloaded_assigned,
                                errors: errors.join(', '),
                                link: view_context.link_to(l('easy_gantt_resources.resource_management'), link))
        end
      end

    end

  end
end
RedmineExtensions::PatchManager.register_controller_patch 'IssuesController', 'EasyGanttResources::IssuesControllerPatch'
