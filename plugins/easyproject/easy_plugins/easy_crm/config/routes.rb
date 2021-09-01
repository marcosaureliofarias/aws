get 'easy_crm_settings', to: 'easy_crm_settings#index', as: 'easy_crm_settings_global'
put 'easy_crm_settings/save_global_settings', :as => 'save_global_easy_crm_settings'
get 'easy_crm_kanban_settings' => 'easy_crm_kanban#settings', :as => 'easy_crm_kanban_settings'
match 'easy_crm_kanban_settings' => 'easy_crm_kanban#save_settings', :as => 'easy_crm_kanban_settings_save', :via => [:post, :put]

resources :easy_crm_cases do
  collection do
    match 'bulk_edit', :via => [:get, :post]
    post 'bulk_update'
    get 'context_menu'
    get 'find_by_worker'
    get 'merge', to: 'easy_crm_cases#merge_edit'
    put 'merge', to: 'easy_crm_cases#merge_update'
    get 'render_assignments_form_on_issue'
  end

  member do
    get 'toggle_description'
    get 'add_or_create_related_easy_contact', :to => 'easy_crm_related_easy_contacts#index', :as => 'add_or_create_related_easy_contact'
    post 'add_related_easy_contact', :to => 'easy_crm_related_easy_contacts#create', :as => 'add_related_easy_contact'
    get 'add_or_create_related_easy_invoice', :to => 'easy_crm_related_easy_invoices#index', :as => 'add_or_create_related_easy_invoice'
    post 'add_related_easy_invoice', :to => 'easy_crm_related_easy_invoices#create', :as => 'add_related_easy_invoice'
    get 'add_or_create_related_issue', :to => 'easy_crm_related_issues#index', :as => 'add_or_create_related_issue'
    post 'add_related_issue', :to => 'easy_crm_related_issues#create', :as => 'add_related_issue'
    delete 'delete_related_easy_contact', :to => 'easy_crm_related_easy_contacts#destroy', :as => 'delete_related_easy_contact'
    match 'preview_external_email', :to => 'easy_external_emails#preview_external_email', :defaults => {:entity_type => 'EasyCrmCase'}, :as => 'preview_external_email', :via => [:get, :post]
    get 'items', :to => 'easy_crm_case_items#edit_easy_crm_case_items', :as => 'edit_items'
    put 'items', :to => 'easy_crm_case_items#update_easy_crm_case_items', :as => 'update_items'
    delete 'remove_related_invoice', :to => 'easy_crm_cases#remove_related_invoice', :as => 'remove_related_easy_invoice'
    get 'render_tab'
    get 'description_edit'
  end
end

resources :easy_crm_case_items do
  collection do
    get 'context_menu'
    delete 'bulk_destroy'
  end
end

resources :easy_crm_case_statuses do
  member do
    match 'change', :via => [:get, :post]
  end
end
resources :easy_crm_case_mail_templates

get 'easy_crm', :to => 'easy_crm#index'
match 'easy_crm/layout', :to => 'easy_crm#layout', :via => [:get, :post]

post 'easy_crm_cases/add_related_issue', :to => 'easy_crm_related_issues#create', :as => 'add_related_issue_with_post_params'

#get 'easy_crm_cases/:id/toggle_description', :to => 'easy_crm_cases#toggle_description'

# Context menu send `ids`
delete 'easy_crm_cases', :to => 'easy_crm_cases#destroy'

resources :easy_crm_country_values do
  collection do
    get 'autocomplete'
    get 'bulk_edit'
    post 'bulk_update'
    get 'context_menu'
  end
end

resources :projects do
  member do
    get 'easy_crm_contacts', :to => 'easy_crm_contacts#index'
    get 'easy_crm_settings', :to => 'easy_crm_settings#project_index', :as => 'easy_crm_settings'
    put 'easy_crm_settings', :to => 'easy_crm_settings#save_project_settings', :as => 'save_easy_crm_settings'
    get 'easy_crm_kanban' => 'easy_crm_kanban#show', :as => 'easy_crm_kanban'
    get 'easy_crm_kanban_settings' => 'easy_crm_kanban#settings', :as => 'easy_crm_kanban_settings'
    match 'easy_crm_kanban_settings' => 'easy_crm_kanban#save_settings', :as => 'easy_crm_kanban_settings_save', :via => [:post, :put]
    post 'easy_crm_kanban/assign_entity' => 'easy_crm_kanban#assign_entity', :as => 'easy_crm_kanban_assign_entity'
  end

  get 'easy_crm', :to => 'easy_crm#project_index'
  resources :easy_crm do

    collection do
      match 'layout', :to => 'easy_crm#project_layout', :via => [:get, :post]
    end

  end

  resources :easy_crm_cases
  resources :easy_crm_case_mail_templates
end

match 'easy_crm_charts/user_performance_chart', :to => 'easy_crm_charts#user_performance_chart', :via => [:get, :post]
match 'easy_crm_charts/pie_chart_from_custom_field', :to => 'easy_crm_charts#pie_chart_from_custom_field', :via => [:get, :post]
match 'easy_crm_charts/user_compare_chart', :to => 'easy_crm_charts#user_compare_chart', :via => [:get, :post]

get 'sale_activities', :to => 'easy_crm_cases#sales_activities', :as => 'sales_activities'

match 'workflows/crm_permissions', :to => 'workflows#crm_permissions', :via => [:get, :post]


resources :easy_user_targets, :only => [:index] do
  collection do
    post 'bulk_update'
    match 'add_user', :via => [:get, :post]
    put 'set_user_target_currency'
    delete 'remove_user'
    get 'bulk_edit'
  end
end

# my
post 'my/create_crm_case_from_module', to: 'my#create_crm_case_from_module'
get 'my/create_crm_case_from_module', to: 'my#page'
match 'my/update_my_page_new_easy_crm_case_attributes', to: 'my#update_my_page_new_easy_crm_case_attributes', as: :update_my_page_new_easy_crm_case, via: [:get, :post]
