FactoryBot.define do
  factory :re_artifact_properties do
    association :created_by, factory: :user
    association :updated_by, factory: :user
    project
    artifact_type { 'Project' }
    sequence(:artifact_id) { |n| n }
    sequence(:description) { |n| "Description #{n}" }
    sequence(:name) { |n| "Name #{n}" }
  end
end