# frozen_string_literal: true

module PermissionResolvers
  class Project < PermissionResolver
    register_for 'Project'

    def resolve_visibility(key)
      case key
      when :total_estimated_hours, :total_spent_hours
        object.module_enabled?(:time_tracking) && ::User.current.allowed_to?(:view_time_entries, object)
      end
    end

  end
end

