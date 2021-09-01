require 'easy_extensions/spec_helper'

feature 'Easy User Time Calendar', logged: :admin do

  let(:default_calendar) { EasyUserTimeCalendar.default }

  it 'check working days in week' do
    visit edit_easy_user_working_time_calendar_path(default_calendar)
    fill_in("easy_user_working_time_calendar_default_working_hours", :with => 5)
    click_button(I18n.t(:button_update))

    date = Date.commercial(Date.today.year, Date.today.cweek, default_calendar.first_day_of_week)
    default_calendar.reload

    expect(default_calendar.weekend?(date)).to be false
    expect(default_calendar.default_working_hours).to eq(5.0)
    expect(default_calendar.working_hours(date)).to eq(5.0)

  end
end
