match 'easy_helpdesk', :to => 'easy_helpdesk#index', :via => [:get, :put]
match 'easy_helpdesk/layout', :to => 'easy_helpdesk#layout', :via => [:get, :post]
match 'easy_helpdesk/settings', :to => 'easy_helpdesk#settings', :via => [:get, :put], :as => 'easy_helpdesk_settings'

resources :easy_helpdesk_projects do

  collection do
    get :bulk_edit
    post :bulk_update
    delete :destroy
    get :copy_sla
    get :find_by_email
  end

  resources :easy_helpdesk_project_matching

end

resources :easy_helpdesk_mail_templates
resources :easy_helpdesk_mailboxes

get 'context_menus/easy_helpdesk_projects', :to => 'context_menus#easy_helpdesk_projects'
get 'easy_auto_completes/easy_helpdesk_projects', :to => 'easy_auto_completes#easy_helpdesk_projects'

resources :projects do
  resources :easy_sla_events, only: [:index, :destroy]
end

resources :easy_sla_events do
  collection do
    get 'context_menu'
  end
end
