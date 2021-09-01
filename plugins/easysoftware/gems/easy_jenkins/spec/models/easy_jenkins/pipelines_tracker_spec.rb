require_relative '../../spec_helper'

RSpec.describe EasyJenkins::PipelinesTracker, type: :model do
  it 'should belong_to pipeline' do
    pipeline = described_class.reflect_on_association(:pipeline)
    expect(pipeline.macro).to eq(:belongs_to)
  end

  it 'should belong_to tracker' do
    tracker = described_class.reflect_on_association(:tracker)
    expect(tracker.macro).to eq(:belongs_to)
  end
end
