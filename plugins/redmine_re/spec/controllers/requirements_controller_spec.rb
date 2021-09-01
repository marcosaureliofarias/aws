require_relative "../spec_helper"
require_relative '_controller_requirements'

describe RequirementsController, type: 'controller' do

  context 'with anonymous user' do
    let(:project) { create(:project) }

    it_should_behave_like :controller_requirements
  end


  context 'with logged user without membership', logged: true do
    let(:project) { create(:project) }

    before :each do
      role = Role.non_member
      role.reload
    end

    it_should_behave_like :controller_requirements
  end


  context 'with logged user with membership', logged: true do
    let(:project) { create(:project, members: [User.current], add_modules: ['requirements']) }

    before :each do
      role = Role.non_member
      role.add_permission!(:edit_requirements)
      role.reload
    end

    context 'first load' do
      it_should_behave_like :controller_requirements
    end

    context 'configured' do
      context 'with artifact' do
        let(:artifact_properties) do
          create(
            :re_artifact_properties,
            project: project,
            created_by: User.current.id,
            updated_by: User.current.id,
            artifact_id: project.id
          )
        end

        before :each do
          allow(ReArtifactProperties).to receive(:find_by).and_return(artifact_properties)
          allow(ReSetting).to receive(:get_plain).and_return("false")
          allow(ReSetting).to receive(:active_re_artifact_settings).and_return({})
          allow(ReSetting).to receive(:active_re_relation_settings).and_return({})
        end

        it_should_behave_like :controller_requirements, true

        describe 'GET #delegate_tree_drop' do
          it 'should move artifact properties' do
            artifact_properties_parent = create(
              :re_artifact_properties,
              project: project,
              created_by: User.current.id,
              updated_by: User.current.id,
              artifact_id: project.id
            )

            get :delegate_tree_drop, params: {
                project_id: project.id,
                id: artifact_properties.id,
                position: 0,
                parent_id: artifact_properties_parent.id
            }

            expect(response).to have_http_status(200) # success
          end
        end
      end

      context 'without artifact' do
        it_should_behave_like :controller_requirements, false
      end

      describe 'GET #sendDiagramPreviewImage' do
        # TODO: I don't have diagram module
      end

      describe 'GET #add_relation' do
        # Seems that it is never used
        # TODO: When editing artifact, there is possibility to create relation which does not work. Should it use this method?
      end

    end

  end
end