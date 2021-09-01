resources :projects do
  resources :easy_checklists
end

resources :easy_checklists do
  collection do
    post :add_to_entity
    get :append_template
    match :settings, :via => [:get, :put]
  end
  member do
    put :update_display_mode

    scope  :controller => 'easy_checklist_items' do
      get 'item', :action => 'new'
      post 'item', :action => 'create'
      put 'item/:easy_checklist_item_id', :action => 'update', :as => :update_item
      delete 'item/:easy_checklist_item_id', :action => 'destroy', :as => :delete_item
    end
  end
end
resources :easy_checklist_items, :except => [:show, :index]