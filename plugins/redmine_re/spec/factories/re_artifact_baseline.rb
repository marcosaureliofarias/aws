FactoryBot.define do
  factory :re_artifact_baseline do
    association :project
    sequence(:description) { |n| "Description #{n}" }
    sequence(:name) { |n| "Name #{n}" }
  end
end