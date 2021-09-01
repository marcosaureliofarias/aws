RSpec.describe EasySsoSamlClientCallbacksController do

  let(:saml_response) { File.read(local_file_fixture("saml_response_signed_assertion.xml")) }

  around(:each) do |example|
    with_easy_settings(easy_sso_saml_client_debug:       nil,
                       easy_sso_saml_client_idp_checked: '1',
                       easy_sso_saml_client_validation:  '0'
                      ) do
      example.run
    end
  end

  describe '#easy_sso_saml_consume' do
    context 'validation' do
      around(:each) do |example|
        with_easy_settings(easy_sso_saml_client_onthefly_creation: '1') do
          example.run
        end
      end

      context 'enabled' do
        around(:each) do |example|
          with_easy_settings(easy_sso_saml_client_validation: '1') do
            example.run
          end
        end
        it 'response valid' do
          allow_any_instance_of(OneLogin::RubySaml::Response).to receive(:is_valid?).and_return(true)
          expect {
            post :easy_sso_saml_consume, params: { SAMLResponse: saml_response }
          }.to change { User.logged.count }.by(1)
          expect(response).to have_http_status(:redirect)
        end
        it 'response invalid' do
          allow_any_instance_of(OneLogin::RubySaml::Response).to receive(:is_valid?).and_return(false)
          expect {
            post :easy_sso_saml_consume, params: { SAMLResponse: saml_response }
          }.not_to change { User.logged.count }
          expect(flash[:error]).to include('SAML ERROR:')
          expect(response).to have_http_status(:redirect)
        end
      end

      context 'disabled' do
        it 'response parseable' do
          expect {
            post :easy_sso_saml_consume, params: { SAMLResponse: saml_response }
          }.to change { User.logged.count }.by(1)
          expect(response).to have_http_status(:redirect)
        end
        it 'response not parseable' do
          expect {
            post :easy_sso_saml_consume, params: { SAMLResponse: '' }
          }.not_to change { User.logged.count }
          expect(subject).to render_template(:register)
        end
      end

    end

    context 'existing user' do
      let(:user_active) { FactoryBot.create(:user, login: OneLogin::RubySaml::Response.new(saml_response).name_id) }
      let(:user_inactive) { FactoryBot.create(:user, login: OneLogin::RubySaml::Response.new(saml_response).name_id, status: User::STATUS_LOCKED) }

      around(:each) do |example|
        with_easy_settings(easy_sso_saml_client_name_identifier_value: 'login',
                           easy_sso_saml_client_onthefly_creation:     '0',
                          ) do
          example.run
        end
      end
      it 'active' do
        user_active
        post :easy_sso_saml_consume, params: { SAMLResponse: saml_response }
        expect(User.current).to eq(user_active)
        expect(response).to have_http_status(:redirect)
      end
      it 'inactive' do
        user_inactive
        post :easy_sso_saml_consume, params: { SAMLResponse: saml_response }
        expect(User.current).to eq(User.anonymous)
        expect(flash[:error]).not_to be_empty
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'new user' do
      around(:each) do |example|
        with_easy_settings(easy_sso_saml_client_name_identifier_value: 'login',
                           easy_sso_saml_client_onthefly_creation:     '1',
                          ) do
          example.run
        end
      end
      it 'on-the-fly pass' do
        expect {
          post :easy_sso_saml_consume, params: { SAMLResponse: saml_response }
        }.to change { User.logged.count }.by(1)
        user = User.last
        expect(user.login).to eq('test')
        expect(user.mail).to eq('test@example.com')
        expect(user.firstname).to eq('John')
        expect(user.lastname).to eq('Doe')
        expect(response).to have_http_status(:redirect)
      end
      it 'on-the-fly fail' do
        allow_any_instance_of(AnonymousUser).to receive(:save).and_call_original
        allow_any_instance_of(User).to receive(:save).and_return(false)
        expect {
          post :easy_sso_saml_consume, params: { SAMLResponse: saml_response }
        }.not_to change { User.logged.count }
        expect(subject).to render_template(:register)
      end
      it 'on-the-fly disabled' do
        with_easy_settings(easy_sso_saml_client_onthefly_creation: '0') do
          expect {
            post :easy_sso_saml_consume, params: { SAMLResponse: saml_response }
          }.not_to change { User.logged.count }
          expect(flash[:error]).not_to be_empty
          expect(response).to have_http_status(:redirect)
        end
      end
    end

  end

  private

  def local_file_fixture(filename)
    File.dirname(__FILE__) + '/../fixtures/files/' + filename
  end

end
