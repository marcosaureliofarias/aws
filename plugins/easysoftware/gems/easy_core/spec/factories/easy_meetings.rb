FactoryBot.define do
  factory :easy_meeting do
    sequence(:name) { |n| "Meeting no. #{n}" }
    description { 'This will be a really great meeting!' }
    start_time { Time.now + (1 + Random.rand(40)).hours }
    end_time { start_time + (1 + Random.rand(3)).hours }

    author

    before :create do |easy_meeting, _evaluator|
      easy_meeting.user_ids = [easy_meeting.author_id] if easy_meeting.user_ids.empty?
    end

    trait :all_day do
      all_day { true }
    end

    trait :with_users do
      transient do
        number_of_users { 2 }
      end
      after :build do |easy_meeting, evaluator|
        easy_meeting.user_ids = FactoryBot.create_list(:user, evaluator.number_of_users).map(&:id)
      end
    end

    trait :recurring do
      easy_is_repeating { true }
      easy_repeat_settings { Hash[ 'period' => 'daily', 'daily_option' => 'each', 'daily_each_x' => '1', 'endtype' => 'endless' ] }
    end

    trait :big_recurring do
      big_recurring { true }
    end


    factory :all_day_easy_meeting, traits: [:all_day]
    factory :big_repeating_meeting, traits: [:recurring, :big_recurring]
  end
end
FactoryBot.define do
  factory :easy_invitation do
    association :user, firstname: "Invited"
    association :easy_meeting
  end
end
