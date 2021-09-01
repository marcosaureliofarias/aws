# easy_calculation
get 'projects/:id/cost_estimation', :to => 'easy_calculation#show', :as => 'easy_calculation'
put 'projects/:id/cost_estimation_order', :to => 'easy_calculation#order', :as => 'easy_calculation_order'
post 'projects/:id/cost_estimation/save_to_money', :to => 'easy_calculation#save_to_easy_money', :as => 'save_calculation_to_money'
get 'projects/:id/cost_estimation/preview', :to => 'easy_calculation#preview', :as => 'easy_calculation_preview'
get 'cost_estimation/settings', :to => 'easy_calculation#settings', :as => 'easy_calculation_settings'
post 'cost_estimation/settings', :to => 'easy_calculation#save_settings'
get 'projects/:id/cost_estimation/description', :to => 'easy_calculation#description', :as => 'easy_calculation_description'
put 'projects/:id/cost_estimation', :to => 'easy_calculation#update', :as => 'easy_calculation_update'

# easy_calculation_items
resources :easy_calculation_items do
  member do
    post :add_issue
    delete :remove_issue
  end
end
