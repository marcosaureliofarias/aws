require_relative '../../spec_helper'

RSpec.describe EasyJenkins::PipelinesIssue, type: :model do
  it 'should belong_to pipeline' do
    pipeline = described_class.reflect_on_association(:pipeline)
    expect(pipeline.macro).to eq(:belongs_to)
  end

  it 'should belong_to issue' do
    issue = described_class.reflect_on_association(:issue)
    expect(issue.macro).to eq(:belongs_to)
  end
end