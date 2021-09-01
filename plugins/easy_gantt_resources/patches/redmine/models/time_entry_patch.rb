module EasyGanttResources
  module TimeEntryPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        # after_save :decrease_issue_easy_gantt_resources
        # after_destroy :increase_issue_easy_gantt_resources

        after_save :reallocate_easy_gantt_resources
        after_destroy :reallocate_easy_gantt_resources
      end
    end

    module InstanceMethods

      private

        def reallocate_easy_gantt_resources
          if destroyed? || saved_change_to_hours? || saved_change_to_issue_id? || saved_change_to_project_id?
            if issue_id_before_last_save
              old_issue = Issue.find_by(id: issue_id_before_last_save)
              old_issue.reallocate_resources if old_issue
            end

            current_issue = issue
            current_issue.reallocate_resources if current_issue
          end
        end

      # def decrease_issue_easy_gantt_resources
      #   return if issue.blank? || hours <= 0

      #   hours_to_deallocate = hours

      #   allocations = issue.easy_gantt_resources.reorder('date ASC').to_a
      #   allocations.each do |allocation|
      #     break if hours_to_deallocate <= 0
      #     next if allocation.hours <= 0

      #     if allocation.hours >= hours_to_deallocate
      #       allocation.hours -= hours_to_deallocate
      #       hours_to_deallocate = 0
      #     else
      #       hours_to_deallocate -= allocation.hours
      #       allocation.hours = 0
      #     end
      #   end

      #   allocations.each(&:save)
      # end

    end

  end
end
RedmineExtensions::PatchManager.register_model_patch 'TimeEntry', 'EasyGanttResources::TimeEntryPatch'
