require_relative '../spec_helper'

describe 'EasyCrmCase', logged: true, skip: !Redmine::Plugin.installed?(:easy_crm) do

  let(:user) { FactoryGirl.create(:user) }
  let!(:easy_crm_case) { FactoryGirl.create(:easy_crm_case) }
  let!(:custom_field) { FactoryGirl.create(:easy_crm_case_custom_field, easy_crm_case_status_ids: [easy_crm_case.easy_crm_case_status.id]) }
  let!(:custom_field_invisible) { FactoryGirl.create(:easy_crm_case_custom_field, easy_crm_case_status_ids: [easy_crm_case.easy_crm_case_status.id], allowed_user_ids: [user.id], special_visibility: '1') }

  it 'list available custom fields' do
    cfs = CustomField.visible.to_a
    expect(cfs.include?(custom_field)).to eq true
    expect(cfs.include?(custom_field_invisible)).to eq false
    expect(custom_field.visible_by?(easy_crm_case.project, User.current)).to eq true
    expect(custom_field_invisible.visible_by?(easy_crm_case.project, User.current)).to eq false
  end

end
