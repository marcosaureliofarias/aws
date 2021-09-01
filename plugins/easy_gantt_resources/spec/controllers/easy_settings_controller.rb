require File.expand_path('../../../../easyproject/easy_plugins/easy_extensions/test/spec/spec_helper', __FILE__)

RSpec.describe EasySettingsController, logged: :admin do

  around(:each) do |example|
    with_settings(rest_api_enabled: 1) { example.run }
  end

  it 'update settings' do
    post :update, params: {id: 'easy_gantt_resources', easy_setting: {hours_per_day: '2'}}
    expect(response).to be_successful
    expect(EasySetting.where(name: 'hours_per_day').pluck(:value)).to eq(['2'])
  end

end
