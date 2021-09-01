# Because of plugin deactivations
if Redmine::Plugin.installed?(:easy_gantt_resources)
  get 'easy_gantt_resources', to: 'easy_gantt_resources#index', as: 'easy_gantt_resources'
  get 'easy_light_resources', to: 'easy_light_resources#index', as: 'easy_light_resources'

  scope format: true, defaults: { format: 'json' }, constraints: { format: 'json' } do
    put 'easy_gantt_resources/bulk_update_or_create', to: 'easy_gantt_resources#bulk_update_or_create', as: 'easy_gantt_resources_bulk_update_or_create'
    match 'easy_gantt_resources/data', to: 'easy_gantt_resources#global_data', as: 'global_easy_gantt_resources_data', via: [:get, :post]
    match 'projects/:project_id/easy_gantt_resources/data/:resources_start_date/:resources_end_date', to: 'easy_gantt_resources#project_data', as: 'project_easy_gantt_resources_data', via: [:get, :post]
    match 'easy_gantt_resources/users_sums/:variant/:resources_start_date/:resources_end_date', to: 'easy_gantt_resources#users_sums', as: 'easy_gantt_resources_users_sums', via: [:get, :post]
    match 'easy_gantt_resources/projects_sums/:resources_start_date/:resources_end_date', to: 'easy_gantt_resources#projects_sums', as: 'easy_gantt_resources_projects_sums', via: [:get, :post]

    post '(projects/:project_id)/easy_gantt_reservations/bulk_update_or_create', to: 'easy_gantt_reservations#bulk_update_or_create', as: 'easy_gantt_reservations_bulk_update_or_create'
    delete '(projects/:project_id)/easy_gantt_reservations/bulk_destroy', to: 'easy_gantt_reservations#bulk_destroy', as: 'easy_gantt_reservations_bulk_destroy'
  end

  scope '/easy_gantt_resources', controller: 'easy_gantt_resources',
                                 as: 'easy_gantt_resources',
                                 format: true,
                                 defaults: { format: 'json' },
                                 constraints: { format: 'json' } do
    match 'allocated_issues', via: [:get, :post]
    get 'user_calendar_settings'
  end

  scope 'easy_gantt_reservations', controller: 'easy_gantt_reservations', as: 'easy_gantt_reservations' do
    get 'new'
    get 'unpersisted_reservation_info'
  end
end
