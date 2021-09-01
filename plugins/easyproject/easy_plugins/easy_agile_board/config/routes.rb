get 'projects/:id/agile_board' => 'easy_agile_board#show', as: 'easy_agile_board'
get 'projects/:id/agile_board/:sprint_id/backlog' => 'easy_agile_board#backlog', as: 'easy_agile_board_backlog'
post 'projects/:project_id/agile_board/:id/reorder' => 'easy_sprints#reorder', as: 'easy_scrum_reorder'
get 'projects/:id/agile_board/reorder_project_backlog' => 'easy_agile_board#reorder_project_backlog', as: 'easy_agile_board_reorder_project_backlog'
get 'projects/:id/agile_board/reorder_sprint_backlog' => 'easy_agile_board#reorder_sprint_backlog', as: 'easy_agile_board_reorder_sprint_backlog'
get 'projects/:id/agile_board/:sprint_id/burndown_chart' => 'easy_agile_board#burndown_chart', as: 'easy_agile_board_burndown_chart'
get 'projects/:id/agile_board/:sprint_id/populate' => 'easy_agile_board#populate', as: 'easy_agile_board_populate'
match 'projects/:id/agile_board_settings' => 'easy_agile_board#settings', as: 'easy_agile_board_settings', via: [:get, :post]
match 'projects/:id/agile_board_recalculate' => 'easy_agile_board#recalculate', as: 'easy_agile_board_recalculate', via: [:get, :post]

get 'projects/:id/easy_kanban' => 'easy_kanban#show', as: 'project_easy_kanban'
get 'projects/:id/easy_kanban_changed_issues' => 'easy_kanban#changed_issues', as: 'project_easy_kanban_changed_issues'

get 'projects/:id/easy_kanban/backlog' => 'easy_kanban#backlog', as: 'project_easy_kanban_backlog'
match 'projects/:id/easy_kanban/settings' => 'easy_kanban#settings', as: 'project_easy_kanban_settings', via: [:get, :post]
match 'projects/:id/kanban_recalculate' => 'easy_kanban#recalculate', as: 'easy_kanban_recalculate', via: [:get, :post]
get 'easy_agile_settings' => 'easy_agile_settings#index', as: 'global_easy_agile_settings'
post 'save_easy_agile_settings' => 'easy_agile_settings#save_global_settings', as: 'save_global_easy_agile_settings'
patch 'projects/:project_id/issues/:id/easy_kanban_issues' => 'easy_kanban_issues#update', as: 'issue_easy_kanban_issue'
post  'projects/:project_id/easy_kanban_reorder' => 'easy_kanban_issues#reorder', as: 'easy_kanban_reorder'

patch 'projects/:project_id/issues/:issue_id/easy_scrum_issues' => 'easy_sprints#assign_issue', as: 'issue_easy_scrum_issue'

resources :projects do
  resources :easy_sprints do
    member do
      match 'assign_issue', via: [:patch, :put, :post]
      get 'close_dialog'
      match 'close', via: [:put, :post]
      post 'open'
    end
    collection do
      post 'unassign_issue'
      get 'autocomplete'
    end
  end
end

get 'easy_sprints' => 'easy_sprints#global_index', as: 'easy_sprints'
get 'easy_sprints/new' => 'easy_sprints#new', as: 'new_easy_sprint'
match 'easy_sprints/overview', to: 'easy_sprints#overview', via: [:get, :put], as: :overview_easy_sprints
match 'easy_sprints/layout', to: 'easy_sprints#layout', via: [:get, :post], as: :easy_sprints_layout

get 'swimlane_values', to: 'easy_agile_data#swimlane_values', as: 'swimlane_values'
