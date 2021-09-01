FactoryBot.define do

  factory :eucm_easy_user_time_calendar, class: EasyUserWorkingTimeCalendar do
    name { 'UserCalendar' }
    default_working_hours { 8 }
    first_day_of_week { 1 }

    association :user
    type { 'EasyUserWorkingTimeCalendar' }
  end

  factory :eucm_group, class: Group do
    sequence(:lastname) { |n| "Group ##{n}" }
    status { Principal::STATUS_ACTIVE }
    admin { false }
    type { "Group" }
  end

end
