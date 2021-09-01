require 'easy_extensions/spec_helper'

describe VersionsController, :logged => :admin do

  let(:project) { FactoryGirl.create(:project) }
  let(:version) { FactoryGirl.create(:version, :project => project) }

  render_views

  before(:each) { project.reload }

  it 'bulk edit' do
    get :bulk_edit, :params => { :ids => [version] }
    expect(response).to be_successful
  end

  it 'bulk edit 404' do
    last_version = Version.order(:id).last
    get :bulk_edit, :params => { :ids => [last_version ? last_version.id + 1 : 1] }
    expect(response).to have_http_status(404)
  end

end
