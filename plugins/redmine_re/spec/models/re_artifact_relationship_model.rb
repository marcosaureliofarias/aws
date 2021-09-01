require_relative "../spec_helper"

describe ReArtifactRelationship, type: :model do
  let(:project) { create :project, add_modules: ['requirements'] }
  let(:user) { create :user }
  let(:relation_type) { create :re_relationtype, project_id: project.id }
  let(:artifact_property_1) { create :re_artifact_properties, project: project, created_by: user.id, updated_by: user.id }
  let(:artifact_property_2) { create :re_artifact_properties, project: project, created_by: user.id, updated_by: user.id }

  before :each do
    @relation = ReArtifactRelationship.create! source: artifact_property_1, sink: artifact_property_2, relation_type: relation_type.relation_type
  end

  it 'can create relation between artifact properties' do
    expect(@relation.id).to be_nonzero
    expect(@relation.source_id).to eq(artifact_property_1.id)
    expect(@relation.sink_id).to eq(artifact_property_2.id)
  end

  describe 'scope of_project' do
    it "should list project's relations" do
      relations = ReArtifactRelationship.of_project(project)
      expect(relations.size).to eq(1)
      expect(relations.first.id).to eq(@relation.id)
    end
  end

  # TODO: this method is not working but used somewhere; it expect presence of artifact_id column in re_artifact_relationships table
  describe 'find_all_relations_for_artifact_id' do
    it 'finds all relations' do
      relations = ReArtifactRelationship.find_all_relations_for_artifact_id(artifact_property_2.id)
      expect(relations.size).to eq(1)
      expect(relations.first.id).to eq(@relation.id)
    end
  end

  describe '#position_scope' do
    it 'should list scoped relations' do
      relations = @relation.position_scope
      expect(relations.size).to eq(1)
      expect(relations.first.id).to eq(@relation.id)
    end
  end

  describe '#position_scope_was' do
    it 'should list previous scoped relations' do
      relations = @relation.position_scope
      relations_was = @relation.position_scope_was

      expect(relations_was.size).to eq(1)
      expect(relations_was.first.id).to eq(@relation.id)
      expect(relations_was).to eq(relations)
    end
  end
end
