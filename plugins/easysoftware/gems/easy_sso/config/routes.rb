Rails.application.routes.draw do

  rys_feature 'easy_sso' do
    get 'easy_sso', to: 'easy_sso#index', as: 'easy_sso'
    post 'easy_sso', to: 'easy_sso#save_settings', as: 'easy_sso_settings'
  end

end
