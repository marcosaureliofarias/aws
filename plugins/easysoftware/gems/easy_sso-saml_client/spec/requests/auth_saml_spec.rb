RSpec.describe '/auth/saml', type: :request do

  it 'not configured' do
    with_easy_settings(easy_sso_saml_client_idp_sso_target_url: nil) do
      get '/auth/saml'
      expect(response).not_to be_successful
    end
  end

  it 'configured' do
    identity_provider_url = 'https://identity-provider.example.com'
    assertion_consumer_service_url = 'http://localhost:3000/easy_sso/saml/consume'

    allow_any_instance_of(EasySso::SamlClient::Settings).to receive(:assertion_consumer_service_url).and_return(assertion_consumer_service_url)
    with_easy_settings(easy_sso_saml_client_idp_sso_target_url: identity_provider_url) do

      get '/auth/saml'
      expect(response).to have_http_status(:redirect)

      uri = URI::parse(response.location)
      expect("#{uri.scheme}://#{uri.host}").to eq(identity_provider_url)

      saml_request = Zlib::Inflate.new(-Zlib::MAX_WBITS).inflate(Base64::decode64(CGI::parse(uri.query)['SAMLRequest'][0]))
      expect(saml_request).to include(assertion_consumer_service_url)
    end
  end

end