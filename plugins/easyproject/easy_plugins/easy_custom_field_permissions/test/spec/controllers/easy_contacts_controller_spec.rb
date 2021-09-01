require_relative '../spec_helper'

describe EasyContactsController, logged: true do

  render_views

  let(:user) { FactoryGirl.create(:user) }
  let(:easy_contact_type) { FactoryGirl.create(:easy_contact_type, :personal, easy_user_types: [user.easy_user_type]) }
  let!(:easy_contact) { FactoryGirl.create(:easy_contact, is_public: true, easy_contact_type: easy_contact_type) }
  let!(:custom_field) { FactoryGirl.create(:easy_contact_custom_field, contact_types: [easy_contact_type]) }
  let!(:custom_field_invisible) { FactoryGirl.create(:easy_contact_custom_field, contact_types: [easy_contact_type], allowed_user_ids: [user.id], special_visibility: '1') }

  before(:each) do
    role = Role.non_member
    role.add_permission! :view_easy_contacts, :manage_easy_contacts
  end

  it 'render contact query' do
    get :index
    expect(response).to be_successful
    query_columns = assigns[:query].available_columns.select {|i| i.is_a?(EasyQueryCustomFieldColumn)}.map(&:custom_field)
    expect(query_columns.include?(custom_field)).to be true
    expect(query_columns.include?(custom_field_invisible)).to be false
  end

  it 'show' do
    easy_contact
    easy_contact.reload
    get :show, params: {id: easy_contact}
    expect(response).to be_successful
    expect(assigns[:easy_contact].visible_custom_field_values.map(&:custom_field).include?(custom_field)).to be true
    expect(assigns[:easy_contact].visible_custom_field_values.map(&:custom_field).include?(custom_field_invisible)).to be false
  end

  it 'edit' do
    easy_contact
    easy_contact.reload
    get :edit, params: {id: easy_contact}
    expect(response).to be_successful
    expect(assigns[:easy_contact].visible_custom_field_values.map(&:custom_field).include?(custom_field)).to be true
    expect(assigns[:easy_contact].visible_custom_field_values.map(&:custom_field).include?(custom_field_invisible)).to be false
  end

end if Redmine::Plugin.installed?(:easy_contacts)
