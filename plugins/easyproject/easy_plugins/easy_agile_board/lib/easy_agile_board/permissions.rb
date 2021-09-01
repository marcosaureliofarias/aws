PermissionResolvers::Issue.class_eval do
  def closest_agile_project
    project = object.project
    project.self_and_ancestors.has_module(:easy_scrum_board)
                              .reorder(lft: :desc)
                              .first
  end

  # Based on EasyAgileBoard::Hooks.easy_agile_accessible?

  map_visibility(:easy_sprint) do
    User.current.allowed_to?(:view_easy_scrum_board, closest_agile_project)
  end

  map_editability(:easy_sprint) do
    User.current.allowed_to?(:edit_easy_scrum_board, closest_agile_project)
  end

end
