FactoryGirl.define do

  factory :easy_attendance do
    arrival { Date.new(2019, 06, 17).to_time + 7.hours }
    departure { arrival + 5.hours }
    easy_attendance_activity
    user

    trait :full_day do
      range { EasyAttendance::RANGE_FULL_DAY }
    end

    trait :half_day do
      range { EasyAttendance::RANGE_FORENOON }
    end

    trait :afternoon do
      range { EasyAttendance::RANGE_AFTERNOON }
    end

    trait :vacation do
      approval_status { EasyAttendance::APPROVAL_APPROVED }
      easy_attendance_activity { FactoryGirl.create(:vacation_easy_attendance_activity) }
    end

    factory :full_day_easy_attendance, :traits => [:full_day]
    factory :half_day_easy_attendance, :traits => [:half_day]
    factory :afternoon_easy_attendance, :traits => [:afternoon]
    factory :vacation_easy_attendance, :traits => [:vacation]
  end
end
