FactoryBot.define do
  factory :re_artifact_properties_version do
    association :re_artifact_properties
    association :user, factory: :user
  end
end