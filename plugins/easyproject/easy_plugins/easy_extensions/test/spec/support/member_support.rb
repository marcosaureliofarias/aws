RSpec.shared_context 'members_support' do
  let(:project) { FactoryBot.create(:project) }
  let(:role_1) { FactoryBot.create(:role) }
  let(:role_2) { FactoryBot.create(:role) }
  let(:default_role) { FactoryBot.create(:role) }
  let(:easy_user_type) { FactoryBot.create(:easy_user_type, default_role: default_role) }
  let(:user) { FactoryBot.create(:user, easy_user_type: easy_user_type) }
  let(:user2) { FactoryBot.create(:user, easy_user_type: easy_user_type) }
  let(:member) { FactoryBot.create(:member, project: project, user: user) }
  let(:issue) { FactoryBot.create(:issue, project: project, assigned_to: user) }
  let(:group) { FactoryBot.create(:group, users: [user, user2]) }
end
