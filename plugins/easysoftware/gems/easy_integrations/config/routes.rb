Rails.application.routes.draw do

  # scope ':slug' do
  #   resources :easy_integrations do
  #     collection do
  #       get 'settings/:slug', to: 'easy_integrations#settings', as: :settings
  #     end
  #   end
  # end
  #
  # get 'easy_integrations/:slug', to: 'easy_integrations#index'
  # get 'easy_integrations/:slug/new', to: 'easy_integrations#create'
  # post 'easy_integrations/:slug', to: 'easy_integrations#create'
  #

  #  resources :easy_integrations, param: :slug

  resources :easy_integrations do
    collection do
      get 'settings/:slug', to: 'easy_integrations#settings', as: :settings
    end
  end

end
