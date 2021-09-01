RSpec.describe Issue, logged: :admin do

  describe '#set_easy_duration' do

    let(:issue) { described_class.new(start_date: '2019-05-07', due_date: nil, easy_duration: 5) }

    context 'removing due date' do
      it 'removes duration' do
        expect { issue.set_easy_duration }.to change(issue, :easy_duration).to(nil)
      end
    end

    context 'permissions' do
      let(:tracker) { FactoryBot.build(:tracker) }
      let(:issue) { FactoryBot.build(:issue, tracker: tracker) }
      it 'should not be updatable if disabled in tracker' do
        expect(issue.safe_attribute?('easy_duration')).to be_falsey
      end

      it 'should be updatable if enabled in tracker' do
        tracker.core_fields = tracker.core_fields + ['easy_duration']
        tracker.save(validation: false)
        expect(issue.safe_attribute?('easy_duration')).to be_truthy
      end
    end
  end

end
