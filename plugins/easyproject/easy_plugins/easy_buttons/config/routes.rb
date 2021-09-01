resources :easy_buttons do
  member do
    get 'execute'
    get 'copy'
  end

  collection do
    post 'update_form'
    get 'context_menu'
    delete 'bulk_destroy'
  end
end
