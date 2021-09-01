FactoryBot.define do
  factory :easy_timesheet do
    association :user, factory: :user, firstname: "User"
    start_date { Date.today }
    end_date { Date.today + 1.day }
  end
end
