RSpec.describe EasyServiceManager::Services::EasySetting do

  before(:example) do
    @pkey = OpenSSL::PKey::RSA.new(1024)

    @private_key_file = Tempfile.new('private_key')
    @private_key_file.write(@pkey.to_s)
    @private_key_file.close

    @public_key_file = Tempfile.new('public_key')
    @public_key_file.write(@pkey.public_key.to_s)
    @public_key_file.close

    allow(EasyServiceManager).to receive(:private_key) { @private_key_file.path }
    allow(EasyServiceManager).to receive(:public_key) { @public_key_file.path }
  end

  after(:example) do
    @private_key_file&.unlink
    @public_key_file&.unlink
  end

  it 'Internal user limit' do
    setting = EasySetting.create!(name: 'test', value: '1')

    service1 = EasyServiceManager::Services::EasySetting.new
    service1.value = { 'name' => 'test', 'value' => '2' }
    service1.valid_for = 30
    token = service1.token

    service2 = EasyServiceManager::Services::EasySetting.new
    service2.token = token
    service2.execute

    setting.reload
    expect(setting.value).to eq('2')
  end

end
