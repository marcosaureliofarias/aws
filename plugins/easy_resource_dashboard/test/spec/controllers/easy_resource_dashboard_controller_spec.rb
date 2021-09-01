require 'easy_extensions/spec_helper'

RSpec.describe EasyResourceDashboardController, logged: :admin do

  around(:each) do |example|
    with_settings(rest_api_enabled: 1) { example.run }
  end

  let!(:easy_page) { FactoryBot.create(:easy_page, page_name: 'easy-resource-dashboard') }

  render_views

  it '#index' do
    get :index
    expect(response).to be_successful
  end

  it '#layout' do
    get :layout
    expect(response).to be_successful
  end
end
