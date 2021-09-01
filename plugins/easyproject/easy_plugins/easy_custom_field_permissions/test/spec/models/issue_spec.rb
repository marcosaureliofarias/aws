require_relative '../spec_helper'

describe Issue, logged: true do

  let(:user) { FactoryGirl.create(:user) }
  let!(:issue) { FactoryGirl.create(:issue) }
  let!(:custom_field) { FactoryGirl.create(:issue_custom_field, trackers: [issue.tracker]) }
  let!(:custom_field_invisible) { FactoryGirl.create(:issue_custom_field, trackers: [issue.tracker], allowed_user_ids: [user.id], special_visibility: '1') }

  it 'list available custom fields' do
    cfs = CustomField.visible.to_a
    expect(cfs.include?(custom_field)).to eq true
    expect(cfs.include?(custom_field_invisible)).to eq false
    expect(custom_field.visible_by?(issue.project, User.current)).to eq true
    expect(custom_field_invisible.visible_by?(issue.project, User.current)).to eq false
  end

end
