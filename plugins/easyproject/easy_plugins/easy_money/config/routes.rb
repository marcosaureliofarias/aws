match 'easy_money/move_to_project', :to => 'easy_money#move_to_project', :via => [:get, :post]
match 'easy_money/projects_to_move', :to => 'easy_money#projects_to_move', :via => [:get, :post]

# easy_money_expected_expenses
match 'easy_money_expected_expenses/inline_edit', :controller => 'easy_money_expected_expenses', :action => 'inline_edit', :via => [:get, :post, :put]
match 'easy_money_expected_expenses/inline_update', :controller => 'easy_money_expected_expenses', :action => 'inline_update', :via => [:get, :post, :put]
resources :easy_money_expected_expenses do
  collection do
    get 'bulk_edit'
    put 'bulk_update'
    delete 'bulk_delete'
  end
end

# easy_money_expected_hours
match 'easy_money_expected_hours/inline_update', :to => 'easy_money_expected_hours#inline_update', :via => [:get, :post, :put, :patch, :delete]
match 'easy_money_expected_hours/inline_edit', :to => 'easy_money_expected_hours#inline_edit', :via => [:get, :post, :put, :patch, :delete]

# easy_money_expected_revenues
match 'easy_money_expected_revenues/inline_edit', :controller => 'easy_money_expected_revenues', :action => 'inline_edit', :via => [:get, :post, :put]
match 'easy_money_expected_revenues/inline_update', :controller => 'easy_money_expected_revenues', :action => 'inline_update', :via => [:get, :post, :put]
resources :easy_money_expected_revenues do
  collection do
    get 'bulk_edit'
    put 'bulk_update'
    delete 'bulk_delete'
  end
end

# easy_money_other_expenses
match 'easy_money_other_expenses/inline_edit', :to => 'easy_money_other_expenses#inline_edit', :via => [:get, :post, :put]
match 'easy_money_other_expenses/inline_update', :to => 'easy_money_other_expenses#inline_update', :via => [:get, :post, :put]
resources :easy_money_other_expenses do
  collection do
    get 'bulk_edit'
    put 'bulk_update'
    delete 'bulk_delete'
  end
end

# easy_money_other_revenues
match 'easy_money_other_revenues/inline_edit', :controller => 'easy_money_other_revenues', :action => 'inline_edit', :via => [:get, :post, :put]
match 'easy_money_other_revenues/inline_update', :controller => 'easy_money_other_revenues', :action => 'inline_update', :via => [:get, :post, :put]
resources :easy_money_other_revenues do
  collection do
    get 'bulk_edit'
    put 'bulk_update'
    delete 'bulk_delete'
  end
end

# easy_money_travel_costs
match 'easy_money_travel_costs/inline_edit', :controller => 'easy_money_travel_costs', :action => 'inline_edit', :via => [:get, :post, :put]
match 'easy_money_travel_costs/inline_update', :controller => 'easy_money_travel_costs', :action => 'inline_update', :via => [:get, :post, :put]
resources :easy_money_travel_costs do
  collection do
    get 'bulk_edit'
    put 'bulk_update'
    delete 'bulk_delete'
  end
end

# easy_money_travel_expenses
match 'easy_money_travel_expenses/inline_edit', :controller => 'easy_money_travel_expenses', :action => 'inline_edit', :via => [:get, :post, :put]
match 'easy_money_travel_expenses/inline_update', :controller => 'easy_money_travel_expenses', :action => 'inline_update', :via => [:get, :post, :put]
resources :easy_money_travel_expenses do
  collection do
    get 'bulk_edit'
    put 'bulk_update'
    delete 'bulk_delete'
  end
end

# context_menus
get 'context_menus/easy_money_expected_expenses', :to => 'context_menus#easy_money_expected_expenses'
get 'context_menus/easy_money_expected_revenues', :to => 'context_menus#easy_money_expected_revenues'
get 'context_menus/easy_money_other_expenses', :to => 'context_menus#easy_money_other_expenses'
get 'context_menus/easy_money_other_revenues', :to => 'context_menus#easy_money_other_revenues'
get 'context_menus/easy_money_travel_costs', :to => 'context_menus#easy_money_travel_costs'
get 'context_menus/easy_money_travel_expenses', :to => 'context_menus#easy_money_travel_expenses'
get 'context_menus/easy_money_user_rates', :to => 'context_menus#easy_money_user_rates'


resources :projects do
  resources :easy_money_expected_expenses do
    collection do
      get 'bulk_edit'
      put 'bulk_update'
      delete 'bulk_delete'
    end
  end
  resources :easy_money_expected_revenues do
    collection do
      get 'bulk_edit'
      put 'bulk_update'
      delete 'bulk_delete'
    end
  end
  resources :easy_money_other_expenses do
    collection do
      get 'bulk_edit'
      put 'bulk_update'
      delete 'bulk_delete'
    end
  end
  resources :easy_money_other_revenues do
    collection do
      get 'bulk_edit'
      put 'bulk_update'
      delete 'bulk_delete'
    end
  end
  resources :easy_money_travel_costs do
    collection do
      get 'bulk_edit'
      put 'bulk_update'
      delete 'bulk_delete'
    end
  end
  resources :easy_money_travel_expenses do
    collection do
      get 'bulk_edit'
      put 'bulk_update'
      delete 'bulk_delete'
    end
  end
  resources :easy_money_project_caches

  # easy_money
  get 'easy_money', :to => 'easy_money#project_index'
  get 'easy_money/issues', to: 'easy_money_issues_budget#project_index', as: 'easy_money_project_issues_budget'

  [
    'inline_expected_profit',
    'inline_other_profit',
    'projects_to_move',
    'move_to_project',
    'change_easy_money_type'
  ].each do |action|
    match "easy_money/#{action}", :to => "easy_money##{action}", :via => [:get, :post, :put, :delete]
  end

  # easy_money_expected_payroll_expenses
  [
    'inline_edit',
    'inline_update',
    'inline_expected_payroll_expenses'
  ].each do |action|
    match "easy_money_expected_payroll_expenses/#{action}", :to => "easy_money_expected_payroll_expenses##{action}", :via => [:get, :post, :put, :delete]
    post 'easy_money_expected_payroll_expenses/update', :to => "easy_money_expected_payroll_expenses#update"
  end

  # easy_money_rates
  %w[
    update_rates
    easy_money_rate_roles
    easy_money_rate_time_entry_activities
    easy_money_rate_users
    load_affected_projects
    inline_update
    bulk_edit
    bulk_update
    projects_select
    projects_update
  ].each do |action|
    match "easy_money_rates/#{action}", :to => "easy_money_rates##{action}", :via => [:get, :post, :put, :delete]
  end

  # easy_money_priorities
  resources :easy_money_priorities do
    collection do
      match 'update_priorities_to_projects', :via => [:get, :post]
      match 'update_priorities_to_subprojects', :via => [:get, :post]
    end
  end

  # easy_money_time_entry_expenses
  resources :easy_money_time_entry_expenses do
    collection do
      match 'update_project_time_entry_expenses', :via => [:get, :post]
      match 'update_project_and_subprojects_time_entry_expenses', :via => [:get, :post]
      match 'update_all_projects_time_entry_expenses', :via => [:get, :post]
    end
  end

  # easy_money_travel_costs
  resources :easy_money_travel_costs do
    collection do
      get 'bulk_edit'
      put 'bulk_update'
      delete 'bulk_delete'
    end
  end

  # easy_money_travel_expenses
  resources :easy_money_travel_expenses do
    collection do
      get 'bulk_edit'
      put 'bulk_update'
      delete 'bulk_delete'
    end
  end

  # easy_money_settings
  get 'easy_money_settings', :to => 'easy_money_settings#index'

  [
    'project_settings',
    'move_rate_priority',
    'update_settings',
    'update_settings_to_projects',
    'update_settings_to_subprojects',
    'recalculate',
    'easy_money_rate_priorities'
  ].each do |action|
    match "easy_money_settings/#{action}", :to => "easy_money_settings##{action}", :via => [:get, :post, :put, :delete]
  end

  member do

    get 'easy_money2', :to => 'easy_money_periodical_entities#project_index', :defaults => {:entity_type => 'Project'}, :as => 'easy_money2'
    get 'easy_money_periodical_entities_toggle_overview', :to => 'easy_money_periodical_entities#toggle_entities_overview', :defaults => {:entity_type => 'Project'}

  end

  post 'easy_money/change_easy_money_type', :to => 'easy_money#change_easy_money_type', :as => 'change_easy_money_type'

end

post 'easy_money/change_easy_money_type', :to => 'easy_money#change_easy_money_type', :as => 'change_easy_money_type'
post 'easy_money/render_entity_select'

get 'easy_money', :to => 'easy_money#index'
get 'easy_money/page_layout', to: 'easy_money#layout', as: :easy_money_layout
get 'easy_money/issues', to: 'easy_money_issues_budget#index', as: 'easy_money_issues_budget'

# easy_money_rates
%w[
  update_rates
  easy_money_rate_roles
  easy_money_rate_time_entry_activities
  easy_money_rate_users
  load_affected_projects
  inline_update
  bulk_edit
  bulk_update
  projects_select
  projects_update
].each do |action|
  match "easy_money_rates/#{action}", :to => "easy_money_rates##{action}", :via => [:get, :post, :put, :delete]
end

# easy_money_priorities
resources :easy_money_priorities do
  collection do
    match 'update_priorities_to_projects', :via => [:get, :post]
    match 'update_priorities_to_subprojects', :via => [:get, :post]
  end
end

# easy_money_time_entry_expenses
resources :easy_money_time_entry_expenses do
  collection do
    match 'update_project_time_entry_expenses', :via => [:get, :post]
    match 'update_project_and_subprojects_time_entry_expenses', :via => [:get, :post]
    match 'update_all_projects_time_entry_expenses', :via => [:get, :post]
  end
end

# easy_money_settings
get 'easy_money_settings', :to => 'easy_money_settings#index'

[
  'project_settings',
  'move_rate_priority',
  'update_settings',
  'update_settings_to_projects',
  'update_settings_to_subprojects',
  'recalculate',
  'easy_money_rate_priorities'
].each do |action|
  match "easy_money_settings/#{action}", :to => "easy_money_settings##{action}", :via => [:get, :post, :put, :delete]
end

# easy_money_project_caches
get 'easy_money_project_caches', :to => 'easy_money_project_caches#index'

resources :easy_money_periodical_entities do

  collection do

    post 'entity_bulk_update'

  end

  resources :easy_money_periodical_entity_items

end

get 'easy_money_rates/load_affected_projects'

scope '(/projects/:project_id)' do
  resource :easy_money_issue_budget, only: :index
end

# easy crm
# Because of plugin deactivations
if Redmine::Plugin.installed?(:easy_crm)
  resources :projects do
    get 'easy_money/easy_crm_cases', to: 'easy_money_crm_cases_budget#project_index', as: 'easy_money_project_crm_cases_budget'
  end
  get 'easy_money/easy_crm_cases', to: 'easy_money_crm_cases_budget#index', as: 'easy_money_crm_cases_budget'
end