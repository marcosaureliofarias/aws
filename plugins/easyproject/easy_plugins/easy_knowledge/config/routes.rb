get 'easy_knowledge', :to => 'easy_knowledge#index'
get 'easy_knowledge/overview', :to => 'easy_knowledge#overview', :as => 'easy_knowledge_overview'
get 'easy_knowledge/layout', :to => 'easy_knowledge#layout', :as => 'layout_easy_knowledge'
get 'easy_knowledge/search', :to => 'easy_knowledge#search', :as => 'easy_knowledge_search'
get 'easy_knowledge/toolbar', :to => 'easy_knowledge#show_toolbar', :as => 'easy_knowledge_toolbar'
get 'easy_knowledge/sidebar_categories', :to => 'easy_knowledge#sidebar_categories', :as => 'easy_knowledge_sidebar_categories'

resources :easy_knowledge_categories, :easy_knowledge_globals, :easy_knowledge_projects, :easy_knowledge_users
# alias
get 'easy_knowledge_users/:id', :to => 'easy_knowledge_users#show', :as => 'easy_knowledge_principal'
get 'easy_knowledge_users/:id/edit', :to => 'easy_knowledge_users#edit', :as => 'edit_easy_knowledge_principal'


resources :easy_knowledge_stories do
  member do
    delete :remove_from_entity
    post :remove_from_favorite, :to => 'easy_knowledge_stories#toggle_favorite'
    post :add_to_favorite, :to => 'easy_knowledge_stories#toggle_favorite'
    get :show_partail, :to => 'easy_knowledge_stories#show', as: :show_partial
  end
  collection do
    match :send_recommend_mail, via: [:get, :post]

    post :assign_entities
    delete :bulk_destroy, :to => 'easy_knowledge_stories#destroy'
    put :mark_user_stories_as_read
  end
end

resources :projects do
  resources :easy_knowledge_stories do
    member do
      delete :remove_from_entity
    end
    collection do
      match :send_recommend_mail, via: [:get, :post]

      post :assign_entities
      delete :bulk_destroy, :to => 'easy_knowledge_stories#destroy'
    end
  end

  resources :easy_knowledge_categories
  resources :easy_knowledge_projects
end

get 'projects/:project_id/easy_knowledge_project_stories/:id', to: 'easy_knowledge#show_as_tree', as: 'easy_knowledge_project_show_as_tree'

get 'projects/:project_id/easy_knowledge_project_stories', to: 'easy_knowledge_projects#stories_tree', as: 'easy_knowledge_project_stories_overview'

get 'context_menus/easy_knowledge_stories', :to => 'context_menus#easy_knowledge_stories'

post 'easy_knowledge_stories/:id/add_comment', to: 'easy_knowledge_stories#add_comment' , as: 'easy_knowledge_story_add_comment'
get 'easy_knowledge_stories/:id/diff', to: 'easy_knowledge_stories#diff' , as: 'easy_knowledge_story_diff'
match 'easy_knowledge_stories/:id/render_tabs', :to => 'easy_knowledge_stories#render_tabs', :as => 'easy_knowledge_stories_render_tabs', via: [:get, :post]

match 'easy_knowledge/data', :to => 'easy_knowledge#data', via: [:get, :post]

post 'easy_knowledge_stories/mark_as_read', to: 'easy_knowledge_stories#mark_as_read' , as: 'easy_knowledge_story_mark_as_read'
get 'easy_knowledge_stories/:id/restore', to: 'easy_knowledge_stories#restore', as: 'easy_knowledge_story_restore'

# get 'easy_knowledge_stories/:id(/:client_path)', to: 'easy_knowledge#show_as_tree', as: 'easy_knowledge_show_as_tree'
post 'easy_knowledge_stories/:id/update_category', to: 'easy_knowledge_stories#update_story_category', as: 'easy_knowledge_story_update_story_category'

get 'easy_knowledge/all_langfiles', to: 'easy_knowledge#all_langfiles'
