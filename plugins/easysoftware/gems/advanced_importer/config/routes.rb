Rails.application.routes.draw do

  # Usually definition
  #
  # get 'advanced_importer_issue_1', to: 'issues#index'

  # Conditional definition
  #
  # get 'advanced_importer_issues_2', to: 'issues#index', rys_feature: 'advanced_importer.issue'

  # Conditional block definiton
  #
  # rys_feature 'advanced_importer.issue' do
  #   get 'advanced_importer_issues_3', to: 'issues#index'
  # end

  resources :easy_entity_imports, except: [:new] do
    collection do
      get 'new/:type', to: 'easy_entity_imports#new', as: 'new'
    end
    member do
      post :fetch_preview
      post :assign_import_attribute
      get :generate_xml
      get :generate_xslt
      match :import, via: [:get, :post]
      delete :destroy_import_attribute
    end
  end

end
