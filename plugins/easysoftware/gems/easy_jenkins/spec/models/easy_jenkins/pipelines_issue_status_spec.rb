require_relative '../../spec_helper'

RSpec.describe EasyJenkins::PipelinesIssueStatus, type: :model do
  it 'should belong_to pipeline' do
    pipeline = described_class.reflect_on_association(:pipeline)
    expect(pipeline.macro).to eq(:belongs_to)
  end

  it 'should belong_to issue_status' do
    issue_status = described_class.reflect_on_association(:issue_status)
    expect(issue_status.macro).to eq(:belongs_to)
  end
end
