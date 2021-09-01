require_relative "../../spec_helper"

describe RedmineRe::CopyToProject do
  let(:user) { FactoryBot.create(:user) }
  let!(:project_1) { FactoryBot.create(:project, members: [user]) }
  let!(:project_2) { FactoryBot.create(:project, members: [user]) }

  let!(:relation_type_1) { FactoryBot.create(:re_relationtype, project_id: project_1.id, relation_type: 'parentchild') }
  let!(:relation_type_2) { FactoryBot.create(:re_relationtype, project_id: project_1.id, relation_type: 'dependency') }
  let!(:relation_type_3) { FactoryBot.create(:re_relationtype, project_id: project_1.id, relation_type: 'conflict') }

  let!(:re_setting) { FactoryBot.create(:re_setting, project: project_1) }
  let!(:re_query) { FactoryBot.create(:re_query, project: project_1) }
  let!(:re_status) { FactoryBot.create(:re_status, project: project_1) }
  let!(:re_artifact_properties_1) { FactoryBot.create(:re_artifact_properties, project: project_1, artifact_type: 'Project', created_by: user.id, updated_by: user.id) }

  let(:options) { {} }

  subject { described_class.new(source_project: project_1, target_project: project_2, options: options).call }

  it 'copies requirements from source project to target project'do
    expect {
      subject
    }.to change{ project_2.re_artifact_properties.count }.from(0).to(1).and \
         change{ project_2.re_settings.count }.from(0).to(1).and \
         change{ project_2.re_queries.count }.from(0).to(1).and \
         change{ project_2.re_statuses.count }.from(0).to(1)
  end

  describe 're_artifact_properties attachments' do
    let(:attachment) { FactoryBot.create(:attachment) }
    let!(:re_artifact_properties_1) { FactoryBot.create(:re_artifact_properties, project: project_1, artifact_type: 'Project', created_by: user.id, updated_by: user.id, attachments: [attachment]) }

    it 'copies re_artifact_properties with attachments' do
      subject

      expect(project_2.re_artifact_properties.first.attachments.count).to eq(1)
      expect(project_2.re_artifact_properties.first.attachments.pluck(:project_id)).to match_array([project_2.id])
    end
  end

  describe 're_artifact_properties hierarchy' do
    let!(:re_artifact_properties_2) { FactoryBot.create(:re_artifact_properties, parent: re_artifact_properties_1, project: project_1, artifact_type: 'ReSection', created_by: user.id, updated_by: user.id) }

    context 're_artifact_properties children' do
      it 'has children' do
        subject

        expect(project_2.re_artifact_properties.first.children.count).to eq(1)
        expect(project_2.re_artifact_properties.first.children.pluck(:project_id)).to match_array([project_2.id])
      end
    end

    context 're_artifact_properties conflicts' do
      let!(:re_artifact_relationship_conflict) { FactoryBot.create(:re_artifact_relationship, source: re_artifact_properties_1, sink: re_artifact_properties_2, relation_type: 'conflict' ) }

      it 'has conflicts' do
        subject

        expect(project_2.re_artifact_properties.first.conflict.count).to eq(1)
        expect(project_2.re_artifact_properties.first.conflict.pluck(:project_id)).to match_array([project_2.id])
      end
    end

    context 're_artifact_properties dependencies' do
      let!(:re_artifact_relationship_dependency) { FactoryBot.create(:re_artifact_relationship, source: re_artifact_properties_1, sink: re_artifact_properties_2, relation_type: 'dependency' ) }

      it 'has dependencies' do
        subject

        expect(project_2.re_artifact_properties.first.dependency.count).to eq(1)
        expect(project_2.re_artifact_properties.first.dependency.pluck(:project_id)).to match_array([project_2.id])
      end
    end
  end

  describe 're_artifact_properties issues' do
    let!(:issue_1) { FactoryBot.create(:issue, subject: 'Issue #1', project: project_1) }
    let!(:issue_2) { FactoryBot.create(:issue, subject: 'Issue #1 - Copy', project: project_2) }

    context 'issues_map contains reference to copied issue' do
      let!(:re_artifact_properties_1) { FactoryBot.create(:re_artifact_properties, issues: [issue_1], project: project_1, artifact_type: 'Project', created_by: user.id, updated_by: user.id) }

      let(:issues_map) { { issue_1.id => issue_2 } }
      let(:options) { { issues_map: issues_map } }

      it 'has copied issue' do
        subject

        expect(project_2.re_artifact_properties.first.issues).to match_array([issue_2])
      end
    end

    context 'issues_map does not contain reference to copied issue' do
      let!(:issue_3) { FactoryBot.create(:issue, subject: 'Issue #3') }

      let!(:re_artifact_properties_1) { FactoryBot.create(:re_artifact_properties, issues: [issue_3], project: project_1, artifact_type: 'Project', created_by: user.id, updated_by: user.id) }

      it 'has original issue' do
        subject

        expect(project_2.re_artifact_properties.first.issues).to match_array([issue_3])
      end
    end
  end
end
