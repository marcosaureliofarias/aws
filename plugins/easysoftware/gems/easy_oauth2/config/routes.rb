Rails.application.routes.draw do
  rys_feature 'easy_oauth2' do

    resources :easy_oauth2_applications do
      member do
        get 'authorization'
      end
      collection do
        get 'login'
      end
    end

    get '/auth/easy_oauth2_applications/callback', to: 'easy_oauth2_callbacks#easy_oauth2_applications', as: :callback_easy_oauth2_application

    scope :oauth2 do
      get 'authorize', to: 'easy_oauth2_service#authorize', as: 'oauth2_authorize'
      post 'authorize', to: 'easy_oauth2_service#authorized'

      post 'token', to: 'easy_oauth2_service#access_token', as: 'oauth2_token'
      get 'user', to: 'easy_oauth2_service#user', as: 'oauth2_user'
      get 'access_denied', to: 'easy_oauth2_service#access_denied', as: 'oauth2_access_denied'
    end

  end
end
