require_relative '../spec_helper'

describe 'TimeEntry', logged: true do

  let(:user) { FactoryBot.create(:user) }
  let!(:time_entry) { FactoryBot.create(:time_entry) }
  let!(:custom_field) { FactoryBot.create(:time_entry_custom_field) }
  let!(:custom_field_invisible) { FactoryBot.create(:time_entry_custom_field, allowed_user_ids: [user.id], special_visibility: '1') }

  it 'list available custom fields' do
    cfs = CustomField.visible.to_a
    expect(cfs.include?(custom_field)).to eq true
    expect(cfs.include?(custom_field_invisible)).to eq false
    expect(custom_field.visible_by?(time_entry.project, User.current)).to eq true
    expect(custom_field_invisible.visible_by?(time_entry.project, User.current)).to eq false
  end

end
