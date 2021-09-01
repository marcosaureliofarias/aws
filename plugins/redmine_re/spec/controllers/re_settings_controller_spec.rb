require_relative "../spec_helper"
require_relative '_crud_settings'

describe ReSettingsController, type: :controller do

  context 'with anonymous user' do
    let(:project) { create(:project) }

    it_should_behave_like :crud_settings
  end


  context 'with logged member user', logged: true do
    let(:project) { create(:project, members: [User.current], add_modules: [:requirements]) }

    before do
      role = Role.non_member
      role.add_permission!(:administrate_requirements)
      role.reload
    end

    context 'without artifact' do
      it_should_behave_like :crud_settings
    end

    context 'with artifact' do
      let!(:artifact_properties) do
        create(
          :re_artifact_properties,
          project: project,
          created_by: User.current.id,
          updated_by: User.current.id,
          artifact_id: project.id
        )
      end

      context 'unconfirmed' do
        it_should_behave_like :crud_settings
      end

      context 'confirmed' do
        before :each do
          ReSetting.set_serialized("unconfirmed", project.id, false)
        end

        it_should_behave_like :crud_settings, true
      end

    end
  end
end