require_relative '../spec_helper'

describe EasyCrmCasesController, logged: true do

  render_views

  let(:user) { FactoryGirl.create(:user) }
  let(:easy_crm_case) { FactoryGirl.create(:easy_crm_case) }
  let!(:custom_field) { FactoryGirl.create(:easy_crm_case_custom_field, easy_crm_case_status_ids: [easy_crm_case.easy_crm_case_status.id]) }
  let!(:custom_field_invisible) { FactoryGirl.create(:easy_crm_case_custom_field, easy_crm_case_status_ids: [easy_crm_case.easy_crm_case_status.id], allowed_user_ids: [user.id], special_visibility: '1') }

  before(:each) do
    role = Role.non_member
    role.add_permission! :view_easy_crms, :edit_easy_crm_cases, :manage_easy_crm_page
  end

  it 'render query' do
    get :index
    expect(response).to be_successful
    query_columns = assigns[:query].available_columns.select {|i| i.is_a?(EasyQueryCustomFieldColumn)}.map(&:custom_field)
    expect(query_columns.include?(custom_field)).to be true
    expect(query_columns.include?(custom_field_invisible)).to be false
  end

  it 'show' do
    get :show, params: {id: easy_crm_case}
    expect(response).to be_successful
    expect(assigns[:easy_crm_case].visible_custom_field_values.map(&:custom_field).include?(custom_field)).to be true
    expect(assigns[:easy_crm_case].visible_custom_field_values.map(&:custom_field).include?(custom_field_invisible)).to be false
  end

  it 'edit' do
    get :edit, params: {id: easy_crm_case}
    expect(response).to be_successful
    expect(assigns[:easy_crm_case].visible_custom_field_values.map(&:custom_field).include?(custom_field)).to be true
    expect(assigns[:easy_crm_case].visible_custom_field_values.map(&:custom_field).include?(custom_field_invisible)).to be false
  end

end if Redmine::Plugin.installed?(:easy_crm)