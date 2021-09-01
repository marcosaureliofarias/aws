require_relative "../spec_helper"

describe ReArtifactProperties, type: :model do
  let(:user) { create :user, mail_notification: 'all' }
  let(:other_user) { create :user, mail_notification: 'all' }
  let(:project) { create :project, members: [user], add_modules: ['requirements'] }
  let(:project2) { create :project, members: [user], add_modules: ['requirements'] }
  let(:issue) { create :issue, project: project, author: user, assigned_to: user }

  before :each do
    @artifact = ReArtifactProperties.create!(
      name: 'Artifact 1',
      project_id: project.id,
      created_by: user.id,
      updated_by: user.id,
      artifact_type: 'Project'
    )

    @requirement = ReArtifactProperties.create!(
      name: 'ReRequirement 1',
      project_id: project.id,
      created_by: user.id,
      updated_by: user.id,
      artifact_type: 'Project'
    )

    @relation_type = create(:re_relationtype, project_id: project.id)
    @artifact_requirement = create(:re_artifact_relationship, source_id: @artifact.id, sink_id: @requirement.id, relation_type: 'parentchild')
    @requirement.artifact_type = 'ReRequirement'
    @requirement.parent_relation = @artifact_requirement
    @requirement.issues << issue
    @requirement.save!

    @artifact2 = ReArtifactProperties.create!(
      name: 'Artifact 2',
      project_id: project2.id,
      created_by: user.id,
      updated_by: user.id,
      artifact_type: 'Project'
    )
    @artifact2.issues << issue

    User.admin.each do |user|
      user.mail_notification = 'only_my_events'
      user.save!
    end
  end

  describe 'scope without_project' do
    it 'get 1 artifact' do
      artifacts = ReArtifactProperties.without_projects
      expect(artifacts.size).to eq(1)
    end
  end

  describe 'artifacts persisted' do
    it 'can create artifacts' do
      expect(@artifact.persisted?).to be true
      expect(@requirement.persisted?).to be true
      expect(@artifact2.persisted?).to be true
    end
  end

  describe 'scope of_project' do
    it 'get 2 artifacts' do
      artifacts = ReArtifactProperties.of_project(project)
      expect(artifacts.size).to eq(2)
    end

    it 'get 1 artifact' do
      artifacts = ReArtifactProperties.of_project(project2)
      expect(artifacts.size).to eq(1)
    end
  end

  describe 'scope common_issues' do
    it 'gets 2 artifacts across projects' do
      artifacts = ReArtifactProperties.common_issues([issue])
      expect(artifacts.size).to eq(2)
    end
  end

  # I'm not sure if this method is necessary as it destroys relationships_as_source which have dependent: :destroy
  describe '#destroy' do
  end

  describe 'updated_on' do
    it 'returns updated_at' do
      expect(@artifact.updated_on).to eq(@artifact.updated_at)
    end
  end

  describe 'created_on' do
    it 'returns created_at' do
      expect(@artifact.created_on).to eq(@artifact.created_at)
    end
  end

  # never used
  # describe 'build_artifact' do
  #   it 'creates new artifact' do
  #     requirement = @requirement.build_artifact({}, {})
  #     expect(requirement.id).to be_nil
  #   end
  #
  #   it 'throws exception' do
  #     @requirement.artifact_type = nil
  #     @requirement.save!
  #     expect { @requirement.build_artifact({}, {}) }.to raise_error(StandardError)
  #   end
  # end

  describe 'attributes=' do
    it 'changes artifact type' do
      @requirement.attributes = { artifact_type: 'Hokus' }
      expect(@requirement.artifact_type).to eq('Hokus')
    end

    it 'preserves default action' do
      @requirement.attributes = { name: 'Pokus' }
      expect(@requirement.name).to eq('Pokus')
    end
  end

  describe 'validate' do
    # it just calls super
  end

  describe 'visible?' do
    it 'is visible for a creator' do
      expect(@requirement.visible? user).to eq(true)
    end

    it 'is not visible to current user' do
      expect(@requirement.visible?).to eq(false)
    end
  end

  describe 'notified_users' do
    it 'sends messages only to author' do
      expect(@requirement.notified_users).to eq([user])
    end
  end

  describe 'recipients' do
    it "gets only author's email" do
      expect(@requirement.recipients).to eq([user.mail])
    end
  end

  describe 'available_artifact_types' do
    it 'returns available types' do
      expect(ReArtifactProperties.available_artifact_types.sort).to match_array(['ReRequirement', 'Projec'])
    end
  end

  describe 'position' do
    it 'should return 1' do
      expect(@requirement.position).to eq(1)
    end

    it 'should return 0' do
      expect(@artifact2.position).to eq(0)
    end
  end

  describe 'gather_children' do
    it 'should return 1 children' do
      expect(@artifact.gather_children.size).to eq(1)
    end

    it 'should return 0 children' do
      expect(@artifact2.gather_children.size).to eq(0)
    end
  end

  describe 'siblings' do
    it 'should return self' do
      expect(@requirement.siblings).to eq([@requirement])
    end
  end

  describe 'average_rating' do
    # seems it is used only once in unused view
  end

  describe 'get_traces_as_sink' do
    # never used
  end

  describe 'get_traces_as_source' do
    # never used
  end

  describe 'move' do
    it 'should change parent' do
      @requirement.move(@artifact2, 0)

      expect(@artifact2.gather_children.size).to eq(1)
      expect(@artifact.gather_children.size).to eq(0)
    end
  end
end
