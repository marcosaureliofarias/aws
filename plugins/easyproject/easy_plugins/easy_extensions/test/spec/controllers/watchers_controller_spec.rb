require 'easy_extensions/spec_helper'

describe WatchersController, :logged => :admin do

  let(:issue) { FactoryGirl.create(:issue) }
  let(:group) { FactoryGirl.create(:group) }

  render_views

  it 'new' do
    get :new, :params => { :object_id => issue.id, :object_type => 'issue' }, :xhr => true
    expect(response).to be_successful
  end

  it 'create' do
    FactoryGirl.create(:member, project: issue.project, group: group)
    post :create, params: { object_id: issue.id, object_type: 'issue', watcher: { group_ids: group.id } }
    expect(response).to be_successful
    expect(issue.watcher_group_ids).to include(group.id)
  end

  it 'autocomplete_for_user' do
    get :autocomplete_for_user, :params => { :object_id => issue.id, :object_type => 'issue', :easy_query_q => 'test' }, :xhr => true
    expect(response).to be_successful
  end

end
