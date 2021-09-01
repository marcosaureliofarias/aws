require_relative "../spec_helper"

describe ReArtifactBaselinesController, type: :controller do
  let(:project)  { FactoryBot.create(:project) }

  let!(:re_artifact_baseline) { FactoryBot.create(:re_artifact_baseline, project: project) }

  context 'permissions', logged: true do
    before do
      role = Role.non_member
      role.add_permission!(:edit_requirements)
      role.reload

      project.members << Member.new(project: project, principal: User.current, roles: [role])
      project.enable_module!(:requirements)
      project.reload
    end

    it 'allows GET new' do
      get :new, params: { format: :js, project_id: project.id }, xhr: true

      expect( response ).to have_http_status(200)
    end

    it 'allows POST create' do
      post :create, params: { format: :js, project_id: project.id, re_artifact_baseline: { name: 'baseline' } }, xhr: true

      expect( response ).to have_http_status(200)
    end

    it 'allows GET preview' do
      get :preview, params: { format: :js, project_id: project.id, id: re_artifact_baseline.id }, xhr: true

      expect( response ).to have_http_status(302)
    end

    it 'allows PUT update' do
      put :update, params: { format: :js, project_id: project.id, id: re_artifact_baseline.id, re_artifact_baseline: { name: 'baseline' } }, xhr: true

      expect( response ).to have_http_status(302)
    end

    it 'allows DELETE destroy' do
      delete :destroy, params: { format: :js, project_id: project.id, id: re_artifact_baseline.id }, xhr: true

      expect( response ).to have_http_status(302)
    end

    it 'allows GET revert' do
      get :revert, params: { project_id: project.id, id: re_artifact_baseline.id }

      expect( response ).to have_http_status(302)
    end
  end
end