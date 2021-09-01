FactoryGirl.define do
  factory :easy_user_time_calendar do
    name { 'UserCalendar' }
    default_working_hours { 8 }
    first_day_of_week { 1 }

    association :user
    type { 'EasyUserWorkingTimeCalendar' }

  end

  factory :easy_user_time_calendar_exception do
    working_hours { 2 }

    sequence(:exception_date) { |n| Date.today + n.days }

    association :calendar, factory: :easy_user_time_calendar
  end

end
