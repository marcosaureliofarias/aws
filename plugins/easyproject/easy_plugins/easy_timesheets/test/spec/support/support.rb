RSpec.shared_context 'easy timesheet with rows' do

  let(:calendar) { EasyUserWorkingTimeCalendar.new(name: 'Standard', builtin: true, is_default: true, default_working_hours: 8.0, first_day_of_week: 1) }
  let(:easy_timesheet) { EasyTimesheet.new(user: User.current, period: :month, start_date: '2018-11-1', end_date: '2018-11-30') }

  def new_row(over_time)
    new_row = easy_timesheet.build_new_row
    new_row.over_time = over_time
    new_row
  end

  before(:each) do
    allow_any_instance_of(User).to receive(:current_working_time_calendar).and_return(calendar)

    2.times do
      easy_timesheet.rows << new_row(false)
    end
    3.times do
      easy_timesheet.rows << new_row(true)
    end
  end

end
