require_relative "../spec_helper"

describe ReQueriesController, type: :controller do
  let!(:project)  { FactoryBot.create(:project) }

  context 'logged in', logged: true do
    before do
      role = Role.non_member
      role.add_permission!(:view_requirements)
      role.reload

      project.members << Member.new(project: project, principal: User.current, roles: [role])
      project.enable_module!(:requirements)
      project.reload

      allow(ReSetting).to receive(:get_plain).and_return("false")
      allow(ReSetting).to receive(:active_re_artifact_settings).and_return({})
      allow(ReSetting).to receive(:active_re_relation_settings).and_return({})
    end

    describe '#suggest_artifacts' do
      let!(:artifact_properties_1) { FactoryBot.create(:re_artifact_properties, project: project, artifact_type: 'Project', created_by: User.current.id, updated_by: User.current.id) }
      let(:artifact_properties_2) { FactoryBot.build(:re_artifact_properties, parent: artifact_properties_1, project: project, artifact_type: 'ReSection', created_by: User.current.id, updated_by: User.current.id, artifact_id: artifact_properties_1.id) }

      let(:query) {}

      before do
        relation_type = create(:re_relationtype, project_id: project.id)
        artifact_requirement = create(:re_artifact_relationship, source: artifact_properties_1, sink: artifact_properties_2, relation_type: 'parentchild')

        get :suggest_artifacts, params: { format: :js, project_id: project.id, query: query }, xhr: true
      end

      context 'empty query' do
        it 'returns empty array' do
          expect(response_body).to be_empty
        end
      end

      context 'query with artifact id' do
        let(:query) { artifact_properties_2.id }

        it 'returns artifact' do
          expect(response_body.count).to eq(1)
        end
      end

      context 'query with artifact name' do
        let(:query) { artifact_properties_2.name }

        it 'returns artifact' do
          expect(response_body.count).to eq(1)
        end
      end
    end

    describe '#suggest_issues' do
      let!(:artifact_properties_1) { FactoryBot.create(:re_artifact_properties, project: project, artifact_type: 'Project', created_by: User.current.id, updated_by: User.current.id) }

      let(:issue) { FactoryBot.create(:issue, subject: 'issue') }
      let(:query) {}
      let(:except_ids) {}

      before do
        get :suggest_issues, params: { format: :js, project_id: project.id, query: query, except_ids: except_ids }, xhr: true
      end

      context 'empty query' do
        it 'returns empty array' do
          expect(response_body).to be_empty
        end
      end

      context 'query with issue_id' do
        let(:query) { issue.id }

        it 'returns issue' do
          expect(response_body.count).to eq(1)
        end
      end

      context 'query with issue subject' do
        let(:query) { 'issue' }

        it 'returns issue' do
          expect(response_body.count).to eq(1)
        end
      end

      context 'query with issue subject and except_ids ' do
        let(:issue_1) { FactoryBot.create(:issue, subject: 'issue_1') }
        let(:issue_2) { FactoryBot.create(:issue, subject: 'issue_2') }

        let(:query)      { 'issue' }
        let(:except_ids) { [issue_1.id, issue_2.id] }

        it 'returns matching issues without except_ids' do
          expect(response_body.count).to eq(1)
        end
      end
    end
  end

  def response_body
    JSON.parse(response.body)
  end
end