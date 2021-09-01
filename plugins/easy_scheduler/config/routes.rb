# Because of plugin deactivations
if Redmine::Plugin.installed?(:easy_scheduler)
  get :easy_scheduler, to: 'easy_scheduler#index', as: :easy_scheduler
  get 'easy_scheduler/icalendar.ics', to: 'easy_scheduler#icalendar', as: :easy_scheduler_icalendar, defaults: { format: 'ics' }

  scope :easy_scheduler, controller: :easy_scheduler, as: :easy_scheduler do
    get :personal
    get :user_allocation_data
    get :filtered_issues_data
    get :filtered_easy_crm_cases_data
    get :issues_data
    get :icalendar_link
    get :query_filters
    post :save
  end

  scope :easy_scheduler, controller: :easy_scheduler_entity_modals, as: :easy_scheduler do
    get :combine_modal
    get :easy_entity_activity_modal
    get :reload_contacts
    get :reload_activity_entity
  end

  scope :easy_scheduler_quick, controller: :easy_scheduler_quick, as: :easy_scheduler_quick do
    get :show
    get :setting
    post :save_setting
  end

end
