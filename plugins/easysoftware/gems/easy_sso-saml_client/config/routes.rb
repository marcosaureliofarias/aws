Rails.application.routes.draw do

  rys_feature 'easy_sso.saml_client' do
    post 'easy_sso/saml/consume', to: 'easy_sso_saml_client_callbacks#easy_sso_saml_consume', as: 'easy_sso_saml_client_callback'
    get 'easy_sso/saml/settings', to: 'easy_sso_saml_client_settings#index', as: 'easy_sso_saml_client_settings'
    post 'easy_sso/saml/settings', to: 'easy_sso_saml_client_settings#save_settings'
    post 'easy_sso/saml/new_sp_certificate', to: 'easy_sso_saml_client_settings#new_sp_certificate', as: 'easy_sso_saml_client_new_sp_certificate'
    get 'easy_sso/saml/metadata', to: 'easy_sso_saml_client_settings#metadata', as: 'easy_sso_saml_client_metadata'
  end

end
