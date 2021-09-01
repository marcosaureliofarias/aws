class EasyResourceIssueQuery < EasyGantt::EasyGanttIssueQuery
  include EasyGanttResources::ResourceQueryCommon

  # def entity_scope
  #   scope = super
  #   scope = scope.joins(:project).where(projects: { status: Project::STATUS_ACTIVE })
  #   scope = scope.with_easy_gantt_resources(resources_start_date, resources_end_date).preload(:time_entries)
  #   scope
  # end

end
