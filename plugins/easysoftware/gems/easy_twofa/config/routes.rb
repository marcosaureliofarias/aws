Rails.application.routes.draw do

  rys_feature 'easy_twofa' do
    scope path: 'easy_twofa' do
      get 'setting', to: 'easy_twofa#setting', as: 'setting_easy_twofa'
      post 'save_setting', to: 'easy_twofa#save_setting', as: 'save_setting_easy_twofa'
      post 'setup/:scheme_key', to: 'easy_twofa#setup', as: 'setup_easy_twofa'
      match 'activation', to: 'easy_twofa#activation', as: 'activation_easy_twofa', via: [:get, :post]
      post 'activate', to: 'easy_twofa#activate', as: 'activate_easy_twofa'
      match 'disable', to: 'easy_twofa#disable', as: 'disable_easy_twofa', via: [:get, :post]
      post 'disable_confirm', to: 'easy_twofa#disable_confirm', as: 'disable_confirm_easy_twofa'
      post 'disable/:user_id', to: 'easy_twofa#admin_disable', as: 'admin_disable_easy_twofa'

      get 'remembers', to: 'easy_twofa_remembers#index', as: 'remembers_easy_twofa'
      delete 'destroy/:id', to: 'easy_twofa_remembers#destroy', as: 'destroy_remembered_easy_twofa'
    end

    get 'account/easy_twofa/select_scheme', to: 'account#easy_twofa_select_scheme', as: 'easy_twofa_select_scheme_account'
    post 'account/easy_twofa/setup/:scheme_key', to: 'account#easy_twofa_setup', as: 'easy_twofa_setup_account'
    match 'account/easy_twofa/verification', to: 'account#easy_twofa_verification', as: 'easy_twofa_verification_account', via: [:get, :post]
    post 'account/easy_twofa/verify', to: 'account#easy_twofa_verify', as: 'easy_twofa_verify_account'
  end

end
