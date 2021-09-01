require "easy_extensions/spec_helper"

RSpec.describe ProjectDestroyJob, type: :job do
  let!(:project_not_to_be_destroyed) { FactoryBot.create(:project) }
  let!(:project_to_be_destroyed) { FactoryBot.create(:project, destroy_at: DateTime.now) }

  it 'destroys the project' do
    described_class.perform_now(project_to_be_destroyed.id)
    expect { Project.find(project_to_be_destroyed.id) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'doesn\'t run if the destroying is canceled' do
    described_class.perform_now(project_not_to_be_destroyed.id)
    expect { Project.find(project_not_to_be_destroyed.id) }.not_to raise_error
  end

end