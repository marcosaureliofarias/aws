FactoryGirl.define do
  factory :easy_earned_value do
    sequence(:name) { |n| "EV #{n}" }
    type { 'EasyEarnedValue::EstimatedHours' }
    project_default { false }
    project
  end
end
