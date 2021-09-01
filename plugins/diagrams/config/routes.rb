resources :diagrams do
  get :toggle_position, on: :member
  get :generate, on: :collection
  get :context_menu, on: :collection
  post :save, on: :collection
  delete :bulk_destroy, on: :collection
end