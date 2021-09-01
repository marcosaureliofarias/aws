require 'easy_extensions/spec_helper'

describe MemberRole, logged: :admin do
  let(:member_role) { FactoryBot.create(:member_role) }

  describe '#destroy' do
    it 'valid' do
      member_role
      expect {
        member_role.destroy
      }.to change(MemberRole, :count).by(-1)
    end

    it 'invalid' do
      member_role.update_column(:member_id, 0)
      expect {
        member_role.destroy
      }.to change(MemberRole, :count).by(-1)
    end
  end
end
