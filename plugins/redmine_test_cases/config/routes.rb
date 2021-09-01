
resources :projects do
  resources :test_plans
  resources :test_cases
  resources :test_case_issue_executions
end

resources :test_plans do
  collection do
    get 'autocomplete'
  end
end

match 'test_cases/statistics', :to => 'test_cases#statistics', :via => [:get, :post, :put], :as => 'statistics_test_cases'
match 'test_cases/statistics_layout', :to => 'test_cases#statistics_layout', :via => [:get, :post, :put], :as => 'statistics_layout_test_cases'
resources :test_cases do
  collection do
    get 'autocomplete'
    get 'issues_autocomplete'
    get 'bulk_edit'
    post 'bulk_update'
    get 'context_menu'
  end
end
delete 'test_cases', to: 'test_cases#destroy'

resources :test_case_issue_executions, except: [:new] do
  collection do
    get 'autocomplete'
    get 'authors_autocomplete'
    get 'bulk_edit'
    put 'bulk_update'
    get 'context_menu'
  end
end
get 'test_case_issue_executions/:test_case_id/new', to: 'test_case_issue_executions#new', as: 'new_test_case_issue_execution'
delete 'test_case_issue_executions', to: 'test_case_issue_executions#destroy'

get 'issue/:id/test_cases', to: 'issue_test_cases#list', as: 'issue_test_cases'
post 'issue/:id/test_cases', to: 'issue_test_cases#add'

resources :test_cases_csv_import do
  member do
    post :fetch_preview
    post :assign_import_attribute
    get :generate_xml
    get :generate_xslt
    match :import, via: [:get, :post]
    delete :destroy_import_attribute
  end
end