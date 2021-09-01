RSpec.describe EasySsoSamlClientSettingsController, logged: :admin do

  it '#save_settings' do
    EasySetting.find_or_initialize_by(name: 'selected_identity_provider_name').update_attribute(:value, 'provider')
    EasySetting.find_or_initialize_by(name: 'easy_sso_saml_client_idp_checked').update_attribute(:value, '1')

    post easy_sso_saml_client_settings_path, params: { easy_setting: { easy_sso_saml_client_name: 'client name' } }
    expect(response).to have_http_status(:redirect)

    expect(EasySetting.value(:selected_identity_provider_name)).to be_nil
    expect(EasySetting.value(:easy_sso_saml_client_idp_checked)).to eq(0)
    expect(EasySetting.value(:easy_sso_saml_client_name)).to eq('client name')
  end

  it '#metadata' do
    assertion_consumer_service_url = 'http://localhost:3000/easy_sso/saml/consume'
    allow_any_instance_of(EasySso::SamlClient::Settings).to receive(:assertion_consumer_service_url).and_return(assertion_consumer_service_url)

    get easy_sso_saml_client_metadata_path
    expect(response).to be_successful

    expect(response.content_type).to eq('application/xml')
    expect(response.body).to include(assertion_consumer_service_url)
  end

  it '#new_sp_certificate' do
    EasySetting.find_or_initialize_by(name: 'easy_sso_saml_client_sp_certificate').update_attribute(:value, 'certificate should be here')
    EasySetting.find_or_initialize_by(name: 'easy_sso_saml_client_sp_certificate_private_key').update_attribute(:value, 'private key should be here')

    post easy_sso_saml_client_new_sp_certificate_path, params: { format: :js }
    expect(response).to be_successful

    expect(EasySetting.where(name: 'easy_sso_saml_client_sp_certificate').count).to eq(1)
    expect(EasySetting.where(name: 'easy_sso_saml_client_sp_certificate_private_key').count).to eq(1)
    expect(response.body).to include('-----BEGIN CERTIFICATE-----')
    expect(response.body).to include('-----END CERTIFICATE-----')
    expect(response.body).not_to include('certificate should be here')
  end

end