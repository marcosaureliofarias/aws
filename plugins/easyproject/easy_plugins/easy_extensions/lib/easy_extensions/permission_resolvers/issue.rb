# frozen_string_literal: true

module PermissionResolvers
  class Issue < PermissionResolver
    register_for 'Issue'

    def resolve_visibility(key)
      case key
      when :author, :author_id
        !object.disabled_core_fields.include?('author_id')

      when :assignee, :assigned_to_id, :assigned_to
        !object.disabled_core_fields.include?('assigned_to_id')

      when :estimated_hours
        user.allowed_to?(:view_estimated_hours, project, global: true)

      when :watchers
        user.allowed_to?(:view_issue_watchers, object.project)

      when :spent_hours, :spent_time
        user.allowed_to?(:view_time_entries, object.project)

      end
    end

  end
end

