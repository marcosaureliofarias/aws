FactoryBot.define do
  factory :easy_rake_task do
    type { 'EasyRakeTask' }
    period { 'monthly' }
    interval { 1 }
    next_run_at { Time.now - 1 }

    trait :active do
      active { true }
    end

    factory :easy_rake_task_active, traits: [:active]
  end
end