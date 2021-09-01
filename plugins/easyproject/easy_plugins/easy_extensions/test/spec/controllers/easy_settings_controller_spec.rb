require 'easy_extensions/spec_helper'

describe Admin::EasySettingsController, :type => :controller, :logged => :admin do
  render_views

  it 'show' do
    with_easy_settings('dummy_setting' => 'show_value') do
      get :show, :params => { :format => 'json', :id => EasySetting.find_by(:name => 'dummy_setting').id }
      expect(response).to be_successful
      expect(json.values_at(:value, :name)).to eq(['show_value', 'dummy_setting'])
    end
  end

  it 'update' do
    with_easy_settings('dummy_setting' => 'value') do
      put :update, :params => { :format => 'json', :id => EasySetting.find_by(:name => 'dummy_setting').id, :easy_setting => { :value => 'new_value' } }
      expect(response).to be_successful
      expect(EasySetting.find_by(:name => 'dummy_setting').value).to eq('new_value')
    end
  end

  it 'create' do
    EasySetting.where(:name => 'dummy_setting').destroy_all
    post :create, :params => { :format => 'json', :easy_setting => { :name => 'dummy_setting', :value => 'my_value' } }
    expect(response).to be_successful
    expect(EasySetting.find_by(:name => 'dummy_setting').value).to eq('my_value')
  end

end
