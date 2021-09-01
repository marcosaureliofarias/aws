require 'easy_extensions/spec_helper'

describe PrincipalMembershipsController, logged: :admin do
  let(:project) { FactoryBot.create(:project) }
  let(:default_role) { FactoryBot.create(:role) }
  let(:other_role) { FactoryBot.create(:role) }
  let(:easy_user_type) { FactoryBot.create(:easy_user_type, default_role: default_role) }
  let(:user) { FactoryBot.create(:user, easy_user_type: easy_user_type) }

  it 'should assign default role' do
    post :create, params: { user_id: user.id, membership: { project_ids: Array(project.id) } }, xhr: true
    role_ids = user.memberships.where(project_id: project.id).first.roles.map(&:id)
    expect(role_ids).to match_array [default_role.id]
  end

  it 'should assign selected role and not default role' do
    post :create, params: { user_id: user.id, membership: { project_ids: Array(project.id), role_ids: Array(other_role.id) } }, xhr: true
    role_ids = user.memberships.where(project_id: project.id).first.roles.map(&:id)
    expect(role_ids).to match_array [other_role.id]
  end

end
