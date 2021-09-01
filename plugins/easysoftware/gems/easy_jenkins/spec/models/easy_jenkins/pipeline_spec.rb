require_relative '../../spec_helper'

RSpec.describe EasyJenkins::Pipeline, type: :model do
  it 'should belong_to setting' do
    setting = described_class.reflect_on_association(:setting)
    expect(setting.macro).to eq(:belongs_to)
  end

  describe '#to_s' do
    subject { FactoryBot.create(:pipeline, external_name: 'external_name') }

    it 'returns external_name' do
      expect(subject.to_s).to eq('external_name')
    end
  end
end

