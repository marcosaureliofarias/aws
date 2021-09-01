FactoryGirl.define do

  factory :easy_broadcast do
    association :author, factory: :user
    message { 'Lorem ipsum...' }
    sequence(:start_at) { |n| Time.now + n.days }
    sequence(:end_at) { |n| (Time.now + 5.hours) + n.days }

  end

end
