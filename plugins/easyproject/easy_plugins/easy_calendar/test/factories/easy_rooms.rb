FactoryGirl.define do
  factory :easy_room do
    sequence(:name) { |n| "Room ##{n}" }
    capacity { 3 }
    trait(:unlimited) { capacity { nil } }
    factory :unlimited_easy_room, traits: [:unlimited]
  end
end
