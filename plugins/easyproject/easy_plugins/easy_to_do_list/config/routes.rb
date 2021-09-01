resources :easy_to_do_lists, except: [:new, :edit] do
  get :show_toolbar, on: :collection
  resources :easy_to_do_list_items, except: [:new, :edit]
end
resources :easy_to_do_list_items, except: [:new, :edit]