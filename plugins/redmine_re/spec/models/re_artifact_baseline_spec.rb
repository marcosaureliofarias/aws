require_relative "../spec_helper"

describe ReArtifactBaseline, type: :model do
  let(:user) { FactoryBot.create(:user) }
  let(:project) { FactoryBot.create(:project, members: [user]) }

  let!(:relation_type) { FactoryBot.create(:re_relationtype, project_id: project.id) }

  let!(:re_artifact_properties_1) { FactoryBot.create(:re_artifact_properties, project: project, artifact_type: 'Project', created_by: user.id, updated_by: user.id) }
  let!(:re_artifact_properties_2) { FactoryBot.create(:re_artifact_properties, project: project, parent: re_artifact_properties_1, artifact_type: 'ReSection', created_by: user.id, updated_by: user.id) }
  let!(:re_artifact_baseline)     { FactoryBot.create(:re_artifact_baseline, project: project) }
  let!(:re_artifact_properties_3) { FactoryBot.build(:re_artifact_properties, project: project, parent: re_artifact_properties_2, artifact_type: 'ReSection', created_by: user.id, updated_by: user.id) }

  before do
    re_artifact_properties_1.create_version
    re_artifact_properties_2.create_version
    re_artifact_baseline.bind_current_versions

    re_artifact_properties_2.update(name: 'current')
    re_artifact_properties_2.create_version
    re_artifact_properties_3.save
    re_artifact_properties_3.create_version

    re_artifact_baseline.revert!
  end

  describe '#revert!' do
    it 'reverts re_artifact_properties state to baseline' do
      expect(re_artifact_properties_2.reload.current_version).to eq(1)
      expect(re_artifact_properties_3.reload.parent).to be nil
    end
  end

  describe '#excluded_re_artifact_properties' do
    it 'excludes re_artifact_properties created after baseline' do
      expect(re_artifact_baseline.excluded_re_artifact_properties).to match_array([re_artifact_properties_3])
    end
  end

  describe '#current_version_ids' do
    it 'contains ids of re_artifact_properties_versions created before baseline' do
      expect(re_artifact_baseline.current_version_ids.count).to eq(2)
    end
  end
end