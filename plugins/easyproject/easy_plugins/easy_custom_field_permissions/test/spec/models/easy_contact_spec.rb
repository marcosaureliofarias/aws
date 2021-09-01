require_relative '../spec_helper'

describe 'EasyContact', logged: true, skip: !Redmine::Plugin.installed?(:easy_contacts) do

  let(:user) { FactoryGirl.create(:user) }
  let(:easy_contact_type) { FactoryGirl.create(:easy_contact_type, :personal) }
  let!(:easy_contact) { FactoryGirl.create(:easy_contact, easy_contact_type: easy_contact_type) }
  let!(:custom_field) { FactoryGirl.create(:easy_contact_custom_field, contact_types: [easy_contact_type]) }
  let!(:custom_field_invisible) { FactoryGirl.create(:easy_contact_custom_field, contact_types: [easy_contact_type], allowed_user_ids: [user.id], special_visibility: '1') }

  it 'list available custom fields' do
    cfs = CustomField.visible.to_a
    expect(cfs.include?(custom_field)).to eq true
    expect(cfs.include?(custom_field_invisible)).to eq false
    expect(custom_field.visible_by?(nil, User.current)).to eq true
    expect(custom_field_invisible.visible_by?(nil, User.current)).to eq false
  end


end
