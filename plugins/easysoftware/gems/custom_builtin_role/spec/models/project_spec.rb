RSpec.describe Project do

  let(:project) { FactoryBot.create(:project, is_public: false) }
  let(:role) { FactoryBot.create(:role, :manager) }
  let(:type_without_builtin) { FactoryBot.create(:easy_user_type) }
  let(:type_with_builtin) { FactoryBot.create(:easy_user_type, builtin_role: role) }
  let(:user_without_builtin) { FactoryBot.create(:user, easy_user_type: type_without_builtin) }
  let(:user_with_builtin) { FactoryBot.create(:user, easy_user_type: type_with_builtin) }

  it '#users_with_builtin_roles' do
    expect(project.users_with_builtin_roles).to     include(user_with_builtin)
    expect(project.users_with_builtin_roles).not_to include(user_without_builtin)
  end

end
