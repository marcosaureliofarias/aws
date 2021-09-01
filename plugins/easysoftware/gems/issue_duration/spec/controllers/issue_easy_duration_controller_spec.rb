RSpec.describe IssueEasyDurationController, type: :controller, logged: :admin do

  let(:friday) { Date.new(2019, 03, 01) }
  let(:saturday) { Date.new(2019, 03, 02) }
  let(:sunday) { Date.new(2019, 03, 03) }
  let(:monday) { Date.new(2019, 03, 04) }

  let!(:working_calendar) { EasyUserWorkingTimeCalendar.create(name: 'Standard', builtin: true, is_default: true, default_working_hours: 8.0, first_day_of_week: 1) }

  describe '.calculate_easy_duration' do

    def send_request_calculate_easy_duration(start_date, due_date)
      get :calculate_easy_duration, params: { start_date: start_date, due_date: due_date, format: :json }
    end

    it 'one day duration' do
      send_request_calculate_easy_duration(monday, monday)
      expect(response.body).to eq('1')
    end

    it 'start date in weekend' do
      send_request_calculate_easy_duration(sunday, monday)
      expect(response.body).to eq('2')
    end

    it 'due date in weekend' do
      send_request_calculate_easy_duration(friday, saturday)
      expect(response.body).to eq('2')
    end

    it 'weekend inside range' do
      send_request_calculate_easy_duration(friday, monday)
      expect(response.body).to eq('2')
    end
  end

  describe '.move_date' do

    def send_request_move_date(start_date, easy_duration, easy_duration_unit)
      get :move_date, params: { start_date: start_date, easy_duration: easy_duration, easy_duration_unit: easy_duration_unit, format: :json }
    end

    it 'duration one day' do
      send_request_move_date(monday, 1, 'day')
      expect(response.body).to eq(monday.to_json)
    end

    it 'duration one week' do
      send_request_move_date(monday, 1, 'week')
      expect(response.body).to eq(Date.new(2019, 03, 8).to_json)
    end

    it 'duration one month' do
      send_request_move_date(friday, 1, 'month')
      expect(response.body).to eq(Date.new(2019, 03, 29).to_json)
    end

    it 'due date move after weekend' do
      send_request_move_date(friday, 2, 'day')
      expect(response.body).to eq(monday.to_json)
    end

  end

end
