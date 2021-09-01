RSpec.describe IssueDuration::IssueEasyDurationFormatter do

  describe '#easy_duration_formatted' do
    it { expect(described_class.easy_duration_formatted(5, 'day')).to eq('5 Days') }
    it { expect(described_class.easy_duration_formatted(nil, 'week', 'nada')).to eq('nada') }
  end

end
