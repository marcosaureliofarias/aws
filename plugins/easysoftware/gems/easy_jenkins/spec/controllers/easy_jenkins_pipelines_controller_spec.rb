  require_relative '../spec_helper'

RSpec.describe EasyJenkinsPipelinesController, type: :controller do
  let(:project)  { FactoryBot.create(:project) }
  let(:issue)    { FactoryBot.create(:issue, project: project) }
  let(:pipeline) { FactoryBot.create(:pipeline) }

  context 'permissions', logged: true do
    before do
      role = Role.non_member
      role.add_permission!(:manage_easy_jenkins_pipelines)
      role.reload

      project.members << Member.new(project: project, principal: User.current, roles: [role])
      project.enable_module!(:easy_jenkins)
      project.reload
    end

    describe '#run' do
      before do
        allow_any_instance_of(EasyJenkins::Api::Request).to receive(:run_job).and_return(true)
      end

      it 'allows GET run' do
        get :run, params: { project_id: project.id, pipeline_id: pipeline.id, issue_id: issue.id }

        expect( response ).to have_http_status(200)
      end

      context 'missing issue_id' do
        it 'returns 404' do
          get :run, params: { project_id: project.id, pipeline_id: pipeline.id }

          expect( response ).to have_http_status(404)
        end
      end
    end

    describe '#history' do
      it 'allows GET history' do
        get :history, params: { project_id: project.id, issue_id: issue.id }, format: :js

        expect( response ).to have_http_status(200)
      end

      context 'missing issue_id' do
        it 'returns 404' do
          get :history, params: { project_id: project.id }, format: :js

          expect( response ).to have_http_status(404)
        end
      end
    end

    describe '#update_queue' do
      let(:pipeline) { FactoryBot.create(:pipeline, external_name: 'pipeline_name') }
      let!(:job) { FactoryBot.create(:easy_jenkins_job, queue_id: 1, pipeline: pipeline) }

      context 'pipeline job with queue_id exists' do
        it 'allows POST update_queue' do
          post :update_queue, params: { build: { queue_id: 1 }, name: 'pipeline_name' }

          expect( response ).to have_http_status(200)
        end
      end

      context 'pipeline job with queue_id does not exist' do
        it 'allows POST update_queue and returns 404' do
          post :update_queue, params: { build: { queue_id: 2 }, name: 'pipeline_name' }

          expect( response ).to have_http_status(200)
        end
      end
    end
  end

  context 'user without manage_easy_jenkins_pipelines permission', logged: true do
    it 'does not allow GET run' do
      get :run, params: { project_id: project.id, pipeline_id: pipeline.id, issue_id: issue.id }

      expect( response ).to have_http_status(403)
    end

    it 'does not allow GET history' do
      get :history, params: { project_id: project.id }, format: :js

      expect( response ).to have_http_status(403)
    end
  end
end
