match 'easy_contacts/overview', :to => 'easy_contacts#overview', :via => [:get, :post, :put], as: :easy_contacts_overview
match 'easy_contacts/layout', :to => 'easy_contacts#layout', :via => [:get, :post]

resources :easy_contacts_settings do
  member do
    match :contact_type_move, :via => [:get, :post]
  end
end

get 'easy_contacts_settings/edit_field/:field_id', :to => 'easy_contacts_settings#edit_field', as: :edit_field_easy_contacts_setting
match 'easy_contacts_settings/update_field/:field_id', :to => 'easy_contacts_settings#update_field',  as: :update_field_easy_contacts_setting, :via => [:patch, :post, :put]

get 'context_menus/easy_contacts', :to => 'context_menus#easy_contacts'
get 'context_menus/easy_contact_groups', :to => 'context_menus#easy_contact_groups'

get 'easy_contacts/reg_no_query' => 'easy_contacts#reg_no_query', as: 'easy_contacts_reg_no_query', format: :json
get 'easy_contacts/validate_eu_vat_no' => 'easy_contacts#validate_eu_vat_no', as: 'easy_contacts_validate_eu_vat_no', format: :json

resources :easy_contact_types do
  member do
    get :custom_field_mapping
    match :move_easy_contacts, via: [:get, :post]
  end
end

resources :easy_contacts do
  member do
    post :add_note
    post :anonymize
    delete :remove_custom_field
    match :edit_note, via: [:get, :post]
    delete :remove_from_entity
    get :change_avatar
    get :toggle_author_note
    get :render_tab
  end
  collection do
    post :assign_entities
    post :send_contact_by_mail
    post :bulk_anonymize
    get :add_custom_field
    match :destroy_items, via: [:get, :post, :delete]
    match :update_form, via: [:get, :post, :put, :patch, :delete]
    post :find_exist_contact
    delete :remove_custom_field
    get :toggle_display
    match :import_preview, :via => [:get, :post]
    get :import
    get :bulk_edit
    post :merge
    match :bulk_update, via: [:post, :put]
    match :update_bulk_form, via: [:get, :post]
    delete :remove_from_entity
  end
end

resources :easy_contact_groups do
  member do
    post :add_note
    delete :remove_custom_field
    match :edit_note, via: [:get, :post]
    get :toggle_author_note
    post :assign_contact
  end
  collection do
    post :create
    delete :destroy_items
    match :add_custom_field, via: [:get, :post]
    delete :remove_custom_field
  end
end

resources :projects do

  resources :easy_contacts do
    member do
      post :add_note
      delete :remove_custom_field
      match :edit_note, via: [:get, :post]
      delete :remove_from_entity
      get :change_avatar
    end
    collection do
      post :assign_entities
      post :send_contact_by_mail
      get :add_custom_field
      match :destroy_items, via: [:get, :post, :delete]
      match :update_form, via: [:get, :post, :put]
      post :find_exist_contact
      delete :remove_custom_field
      delete :remove_from_entity
    end
  end

  resources :easy_contact_groups do
    member do
      post :add_note
      delete :remove_custom_field
      match :edit_note, via: [:get, :post, :put]
    end
    collection do
      post :create
      delete :destroy_items
      match :add_custom_field, via: [:get, :post, :put]
      delete :remove_custom_field
    end
  end
end

get 'easy_contacts_toolbar/search', :to => 'easy_contacts_toolbar#search'
get 'easy_contacts_toolbar', :to => 'easy_contacts_toolbar#show', :as => 'show_easy_contacts_toolbar'

# carddav
mount EasyContacts::Carddav::Handler.new, :at => '/carddav', :as => 'carddav'
match '/.well-known/carddav' => redirect('/carddav/principal'), :via => :propfind

# my
post 'my/create_contact_from_module', to: 'my#create_contact_from_module'
get 'my/create_contact_from_module', to: 'my#page'
match 'my/update_my_page_new_easy_contact_attributes', to: 'my#update_my_page_new_easy_contact_attributes', as: :update_my_page_new_easy_contact, via: [:get, :post]
