module EasyResourceBase
  module IssuePatch

    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)
      base.class_eval do
        has_many :easy_gantt_resources, dependent: :delete_all

        alias_method_chain :reload, :easy_resource_base
      end
    end

    module InstanceMethods

      def reload_with_easy_resource_base(*args)
        @custom_allocated_hours = nil
        reload_without_easy_resource_base(*args)
      end

      def resource_editable?(user=nil)
        user ||= User.current

        (user.allowed_to?(:edit_easy_gantt, project) ||
         user.allowed_to_globally?(:edit_global_easy_gantt) ||
         (assigned_to_id == user.id &&
          user.allowed_to_globally?(:edit_personal_easy_gantt)))
        # user.allowed_to?(:manage_issue_relations, project) &&
        # user.allowed_to?(:edit_issues, project)
      end

      def custom_allocated_hours
        @custom_allocated_hours ||= easy_gantt_resources.where(custom: true).sum(:hours) || 0.0
      end

      def allocable_errors
        errors = []
        errors << l('easy_gantt_resources.errors.project_is_baseline') unless project.try(:easy_baseline_for_id).nil?
        errors << l('easy_gantt_resources.errors.start_or_due_is_required') if start_date.blank? && due_date.blank?
        errors << l('easy_gantt_resources.errors.estimated_hours_is_blank') if estimated_hours.blank?
        errors << l('easy_gantt_resources.errors.issue_is_closed') if closed?
        errors << l('easy_gantt_resources.errors.project_is_template') if project.try(:easy_is_easy_template?)
        errors
      end

      def resources_editable_errors(user=nil)
        user ||= User.current

        result = []

        if user.allowed_to_globally?(:edit_global_easy_gantt)
          # Global rights
        elsif assigned_to_id == user.id && user.allowed_to_globally?(:edit_personal_easy_gantt)
          # Personal rights
        elsif project && user.allowed_to?(:edit_easy_gantt, project)
          # Project rights
        else
          result << l('easy_gantt_resources.errors.no_rights_for_allocation', issue: subject)
        end

        result
      end

    end

    module ClassMethods
      def load_custom_allocated_hours(issues)
        if issues.any?
          hours_by_issue_id = EasyGanttResource.where(issue_id: issues.map(&:id), custom: true).group(:issue_id).sum(:hours)
          issues.each do |issue|
            issue.instance_variable_set '@custom_allocated_hours', (hours_by_issue_id[issue.id] || 0.0)
          end
        end
      end
    end

  end
end
RedmineExtensions::PatchManager.register_model_patch 'Issue', 'EasyResourceBase::IssuePatch'
