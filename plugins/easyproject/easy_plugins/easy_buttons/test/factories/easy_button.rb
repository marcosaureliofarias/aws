FactoryGirl.define do
  factory :easy_button do
    sequence(:name) {|n| "button #{n}" }
    entity_type { 'Issue' }
    active { true }
    is_private { false }
    silent_mode { false }
  end
end