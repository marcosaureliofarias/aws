Rails.application.routes.draw do

  rys_feature 'easy_sso.saml_server' do
    get '/saml/metadata' => 'account#saml_idp_metadata', as: 'easy_sso_saml_server_metadata'
    #match '/saml/logout' => 'easy_sso_saml_server#logout', via: [:get, :post, :delete]

    get 'easy_sso/saml_server/settings', to: 'easy_sso_saml_server_settings#index', as: 'easy_sso_saml_server_settings'
    post 'easy_sso/saml_server/settings', to: 'easy_sso_saml_server_settings#save_settings'
  end

end
