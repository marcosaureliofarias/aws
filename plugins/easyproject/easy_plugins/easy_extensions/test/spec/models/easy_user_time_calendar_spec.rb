require 'easy_extensions/spec_helper'

describe EasyUserTimeCalendar, :logged => :admin do

  let(:user_calendar) { User.current.current_working_time_calendar }
  let(:exceptions) { FactoryGirl.create_list(:easy_user_time_calendar_exception, 4, calendar: user_calendar) }

  it 'returns exceptions in array' do
    #without cache
    expect(exceptions).to match_array(user_calendar.exception_between(Date.today - 10.days, Date.today + 10.days))
    #from cache
    expect(exceptions).to match_array(user_calendar.exception_between(Date.today - 9.days, Date.today + 9.days))
  end

  it 'parent exceptions' do
    expect(user_calendar.parent_exceptions).to eq([])
  end

end
