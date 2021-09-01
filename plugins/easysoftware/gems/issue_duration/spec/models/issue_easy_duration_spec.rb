RSpec.describe IssueEasyDuration do

  context 'action by calendar' do
    let!(:working_calendar) { EasyUserWorkingTimeCalendar.create(name: 'Standard', builtin: true, is_default: true, default_working_hours: 8.0, first_day_of_week: 1) }
    let(:friday) { Date.new(2019, 03, 01) }
    let(:saturday) { Date.new(2019, 03, 02) }
    let(:sunday) { Date.new(2019, 03, 03) }
    let(:monday) { Date.new(2019, 03, 04) }

    describe '.calculate_easy_duration' do
      it 'one day duration' do
        expect(described_class.easy_duration_calculate(monday, monday)).to eq(1)
      end

      it 'start date in weekend' do
        expect(described_class.easy_duration_calculate(sunday, monday)).to eq(2)
      end

      it 'due date in weekend' do
        expect(described_class.easy_duration_calculate(friday, saturday)).to eq(2)
      end

      it 'weekend inside range' do
        expect(described_class.easy_duration_calculate(friday, monday)).to eq(2)
      end
    end

    describe '.move_date' do
      context 'shift date' do

        it 'duration one day' do
          expect(described_class.move_date(1, 'day', monday)).to eq(monday)
        end

        it 'duration one week' do
          expect(described_class.move_date(1, 'week', monday)).to eq(Date.new(2019, 03, 8))
        end

        it 'duration one month' do
          expect(described_class.move_date(1, 'month', monday)).to eq(Date.new(2019, 04, 1))
        end

        it 'due date move after weekend' do
          expect(described_class.move_date(2, 'day', friday)).to eq(monday)
        end

      end

      context 'unshift date' do

        it 'duration one day' do
          expect(described_class.move_date(1, 'day', nil, monday)).to eq(monday)
        end

        it 'duration one week' do
          expect(described_class.move_date(1, 'week', nil, monday)).to eq(Date.new(2019, 02, 26))
        end

        it 'duration one month' do
          expect(described_class.move_date(1, 'month', nil, monday)).to eq(Date.new(2019, 02, 4))
        end

        it 'due date move after weekend' do
          expect(described_class.move_date(2, 'day', nil, monday).to_s).to eq(friday.to_s)
        end

      end
    end
  end
end
