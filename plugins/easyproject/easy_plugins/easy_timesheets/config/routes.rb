get 'context_menus/easy_timesheets', :to => 'context_menus#easy_timesheets', :as => 'context_menu_easy_timesheets'

resources :easy_timesheets do
  collection do
    get :personal_time_sheet, :to => 'easy_timesheets#personal_show'
    delete :bulk_delete, :to => 'easy_timesheets#destroy'
  end
  member do
    post 'resolve_lock/:lock', :to => 'easy_timesheets#resolve_lock', :as => 'resolve_lock'
    scope  :controller => 'easy_timesheet_cells' do
      get 'cell',   :action => 'show'
      post 'cell',  :action => 'create'
      put 'cell',   :action => 'update'
      delete 'cell',:action => 'destroy'
    end
    scope  :controller => 'easy_timesheet_rows' do
      get 'row', :action => 'new'
      post 'row', :action => 'valid'
      delete 'row', :action => 'delete'
      delete 'row/:row_id/delete', :action => 'destroy', :as => 'delete_row'
    end
  end
end

resources :issues, :only => [:index, :new, :create] do
  resources :time_entries, :controller => 'timelog' do
    collection do
      get 'easy_timesheets'
    end
  end
end

get 'time_entries/easy_timesheets', :to => 'timelog#easy_timesheets'

post 'easy_timesheets_monthly_create', to: 'easy_timesheets#monthly_create', as: 'monthly_create_easy_timesheets'
get 'easy_timesheets_monthly_new', to: 'easy_timesheets#monthly_new', as: 'monthly_new_easy_timesheets'
get 'easy_timesheets/monthly/:id', to: 'easy_timesheets#monthly_show', as: 'monthly_show_easy_timesheets'
post 'monthly_resolve_lock/:lock', to: 'easy_timesheets#monthly_resolve_lock', as: 'monthly_resolve_lock'
