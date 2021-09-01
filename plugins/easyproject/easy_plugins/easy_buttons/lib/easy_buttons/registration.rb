Issue.have_easy_buttons(
  edit_path: lambda { |entity|
    { controller: 'issues', action: 'edit', id: entity.id }
  },
  update_path: lambda { |entity|
    { controller: 'issues', action: 'update', id: entity.id }
  },
  params_name: 'issue'
)

if Redmine::Plugin.installed?(:easy_crm)
  EasyCrmCase.have_easy_buttons(
    edit_path: lambda { |entity|
      { controller: 'easy_crm_cases', action: 'edit', id: entity.id }
    },
    update_path: lambda { |entity|
      { controller: 'easy_crm_cases', action: 'update', id: entity.id }
    },
    params_name: 'easy_crm_case'
  )
end
