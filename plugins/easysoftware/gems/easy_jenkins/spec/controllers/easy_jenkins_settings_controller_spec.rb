require_relative '../spec_helper'

RSpec.describe EasyJenkinsSettingsController, type: :controller do
  let(:project) { FactoryBot.create(:project) }
  let(:params) { { url: 'url', user_name: 'user_name', user_token: 'user_token' } }
  let(:easy_jenkins_setting) { FactoryBot.create(:easy_jenkins_setting) }

  context 'permissions', logged: true do
    before do
      role = Role.non_member
      role.add_permission!(:manage_easy_jenkins_settings)
      role.reload

      project.members << Member.new(project: project, principal: User.current, roles: [role])
      project.enable_module!(:easy_jenkins)
      project.reload
    end

    it 'allows POST create' do
      post :create, params: { project_id: project.id, easy_jenkins_setting: params }

      expect( response ).to have_http_status(302)
    end

    describe '#update' do

      let(:params) { { project_id: project.id } }

      it 'allows PATCH update' do
        patch :update, params: { id: easy_jenkins_setting.id, project_id: project.id, easy_jenkins_setting: params }

        expect( response ).to have_http_status(302)
      end
    end

    it 'allows GET autocomplete_issues' do
      get :autocomplete_issues, params: { project_id: project.id }

      expect( response ).to have_http_status(200)
    end

    describe '#autocomplete_jobs' do
      before do
        allow_any_instance_of(EasyJenkins::Api::Request).to receive(:fetch_jobs).and_return([])
      end

      it 'allows GET autocomplete_jobs' do
        get :autocomplete_jobs, params: { project_id: project.id }

        expect( response ).to have_http_status(200)
      end
    end

    describe '#test_connection' do
      before do
        allow_any_instance_of(EasyJenkins::Api::Request).to receive(:connected?).and_return(true)
      end

      it 'allows GET test_connection' do
        get :test_connection, params: { project_id: project.id }, format: :js

        expect( response ).to have_http_status(200)
      end
    end
  end

  context 'user without manage_easy_jenkins_settings permission', logged: true do
    it 'does not allow POST create' do
      post :create, params: { project_id: project.id, easy_jenkins_setting: params }

      expect( response ).to have_http_status(403)
    end

    it 'does not allow PATCH update' do
      patch :update, params: { id: easy_jenkins_setting.id, project_id: project.id, easy_jenkins_setting: params }

      expect( response ).to have_http_status(403)
    end

    it 'does not allow GET autocomplete_issues' do
      get :autocomplete_issues, params: { project_id: project.id }

      expect( response ).to have_http_status(403)
    end

    it 'does not allow GET autocomplete_jobs' do
      get :autocomplete_jobs, params: { project_id: project.id }

      expect( response ).to have_http_status(403)
    end

    it 'does not allow GET test_connection' do
      get :test_connection, params: { project_id: project.id }, format: :js

      expect( response ).to have_http_status(403)
    end
  end
end
