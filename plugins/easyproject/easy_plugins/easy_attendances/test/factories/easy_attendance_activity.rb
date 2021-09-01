FactoryGirl.define do
  factory :easy_attendance_activity do
    sequence(:name) { |n| "Activity no. #{n}" }
    at_work { true }

    trait :vacation do
      at_work { false }
      approval_required { true }
    end

    factory :vacation_easy_attendance_activity, :traits => [:vacation]
  end
end
