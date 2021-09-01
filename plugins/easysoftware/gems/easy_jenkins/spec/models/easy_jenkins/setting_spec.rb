require_relative '../../spec_helper'

RSpec.describe EasyJenkins::Setting, type: :model do
  it 'should belong_to project' do
    project = described_class.reflect_on_association(:project)
    expect(project.macro).to eq(:belongs_to)
  end
end
