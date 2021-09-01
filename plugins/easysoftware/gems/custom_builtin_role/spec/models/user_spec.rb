RSpec.describe User do

  let(:project) { FactoryBot.create(:project, is_public: false) }
  let(:role) { FactoryBot.create(:role, :manager) }
  let(:type_without_builtin) { FactoryBot.create(:easy_user_type) }
  let(:type_with_builtin) { FactoryBot.create(:easy_user_type, builtin_role: role) }
  let(:user) { FactoryBot.create(:user, easy_user_type: type_without_builtin) }

  it 'project visibility' do
    project; role; type_without_builtin; type_with_builtin; user

    with_current_user(user) do
      expect(Project.visible.count).to be_zero
    end

    user.update_column(:easy_user_type_id, type_with_builtin.id)

    # To clear all cachces
    user1 = User.find(user.id)

    with_current_user(user1) do
      expect(Project.visible.count).to_not be_zero
    end
  end

end
