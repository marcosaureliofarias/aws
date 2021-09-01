RSpec.describe EasySso::SamlClient::User do
  context 'attributes' do
    let(:saml_response) { OneLogin::RubySaml::Response.new(File.read(local_file_fixture('saml_response_signed_assertion.xml')))}
    it '#login' do
      expect(EasySso::SamlClient::User.login(saml_response)).to eq('test')
    end
    it '#mail' do
      expect(EasySso::SamlClient::User.mail(saml_response)).to eq('test@example.com')
    end
    it '#first_name' do
      expect(EasySso::SamlClient::User.first_name(saml_response)).to eq('John')
    end
    it '#last_name' do
      expect(EasySso::SamlClient::User.last_name(saml_response)).to eq('Doe')
    end
  end

  private

  def local_file_fixture(filename)
    File.dirname(__FILE__) + '/../fixtures/files/' + filename
  end
end