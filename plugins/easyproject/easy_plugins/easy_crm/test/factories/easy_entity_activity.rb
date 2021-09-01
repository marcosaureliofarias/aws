FactoryGirl.define do
  factory :easy_entity_activity do
    association :entity, :factory => :easy_crm_case
    association :category, :factory => :easy_entity_activity_category
  end

  factory :easy_entity_activity_category do
    sequence(:name) { |n| "EEAC ##{n}" }
  end
end