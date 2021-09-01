require_relative "../spec_helper"

describe ReArtifactPropertiesVersion, type: :model do
  let(:user) { FactoryBot.create(:user) }
  let(:project) { FactoryBot.create(:project, members: [user]) }
  let!(:relation_type) { FactoryBot.create(:re_relationtype, project_id: project.id) }

  let!(:re_artifact_properties_1) { FactoryBot.create(:re_artifact_properties, project: project, artifact_type: 'Project', created_by: user.id, updated_by: user.id) }
  let!(:re_artifact_properties_2) { FactoryBot.create(:re_artifact_properties, name: 'initial', project: project, parent: re_artifact_properties_1, artifact_type: 'ReSection', created_by: user.id, updated_by: user.id) }
  let(:re_artifact_properties_2_initial_version) { re_artifact_properties_2.re_artifact_properties_versions.ordered.last }

  before do
    re_artifact_properties_1.create_version
    re_artifact_properties_2.create_version
    re_artifact_properties_2.update(name: 'current')
    re_artifact_properties_2.create_version
  end

  describe '#next_version' do
    it 'returns latest version incremented by one' do
      expect(re_artifact_properties_2_initial_version.next_version).to eq(3)
    end
  end

  describe '#self_and_siblings' do
    it 'returns re_artifact_properties_versions relation belonging to re_artifact_properties' do
      expect(re_artifact_properties_2_initial_version.self_and_siblings.count).to eq(2)
    end
  end

  describe '#revert_artifact!' do
    subject { re_artifact_properties_2_initial_version.revert_artifact! }

    it 'reverts re_artifact_properties state to re_artifact_properties_version state' do
      expect { subject }.to change { re_artifact_properties_2.reload.name }.from('current').to('initial')
    end
  end
end