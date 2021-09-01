require 'easy_extensions/spec_helper'

describe Admin::EasyAdminController, logged: false do
  render_views

  context 'monitoring' do

    it 'get html' do
      get :monitoring
      expect(response).to be_successful
      expect(response.body).to include('full_version: ' + EasyExtensions.full_version)
      expect(response.body).to include('platform_version: ' + EasyExtensions.platform_version)
      expect(response.body).to include("<!-- __EP_.O.K.__ SITE: #{Setting.host_name} -->")
    end

    it 'get json' do
      get :monitoring, format: :json
      expect(response).to be_successful
      expect(response.body).to include({ full_version: EasyExtensions.full_version, platform_version: EasyExtensions.platform_version }.to_json)
    end

    it 'get xml' do
      get :monitoring, format: :xml
      expect(response).to be_successful
      expect(response.body).to include({ full_version: EasyExtensions.full_version, platform_version: EasyExtensions.platform_version }.to_xml)
    end

  end

  it 'enabled_plugins' do
    expect(Redmine::Plugin).to receive(:all).and_return [ double( 'Redmine::Plugin',
                                                                 name: 'The plugin name',
                                                                 author: 'The author') ]
    get :enabled_plugins
    expect(response).to be_successful
    expect(response.body).to eq ['The plugin name'].to_json
  end
end
