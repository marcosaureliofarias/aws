require_relative '../spec_helper'

describe IssuesController, logged: true do

  render_views

  let!(:user) { FactoryGirl.create(:user) }
  let(:project) { FactoryGirl.create(:project, members: [user, User.current], is_public: true, trackers: [tracker]) }
  let(:tracker) { FactoryGirl.create(:tracker) }
  let(:issue) { FactoryGirl.create(:issue, project_id: project.id, tracker: tracker) }
  let!(:custom_field) { FactoryGirl.create(:issue_custom_field, trackers: [issue.tracker]) }
  let!(:custom_field_invisible) { FactoryGirl.create(:issue_custom_field, trackers: [issue.tracker], allowed_user_ids: [user.id], special_visibility: '1') }

  before(:each) do
    role = Role.non_member
    role.add_permission! :view_issues
    role.add_permission! :edit_issues
    role.add_permission! :add_issues
  end

  it 'render issue query' do
    get :index
    expect(response).to be_successful
    query_columns = assigns[:query].available_columns.select {|i| i.is_a?(EasyQueryCustomFieldColumn)}.map(&:custom_field)
    expect(query_columns.include?(custom_field)).to be true
    expect(query_columns.include?(custom_field_invisible)).to be false
  end

  it 'show' do
    get :show, params: {id: issue}
    expect(response).to be_successful
    expect(assigns[:issue].visible_custom_field_values.map(&:custom_field).include?(custom_field)).to be true
    expect(assigns[:issue].visible_custom_field_values.map(&:custom_field).include?(custom_field_invisible)).to be false
  end

  it 'edit' do
    get :edit, params: {id: issue}
    expect(response).to be_successful
    expect(assigns[:issue].visible_custom_field_values.map(&:custom_field).include?(custom_field)).to be true
    expect(assigns[:issue].visible_custom_field_values.map(&:custom_field).include?(custom_field_invisible)).to be false
  end

end