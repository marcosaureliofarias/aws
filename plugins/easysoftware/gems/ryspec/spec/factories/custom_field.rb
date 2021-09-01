FactoryBot.define do

  factory :custom_field do

    sequence(:name) { |n| "Custom Field ##{n}" }
    field_format { 'string' }
    min_length { 1 }
    max_length { 300 }
    is_required { false }
    is_for_all { true }
    is_filter { true }
    searchable { true }
    visible { true }

    trait :with_group do
      easy_group factory: :easy_custom_field_group
    end

    trait :computed do
      transient do
        computed_format { 'string' }
        computed_token { '%{issue_id}' }
      end

      after(:build) do |custom_field, evaluator|
        custom_field.settings['easy_computed_token_format'] = evaluator.computed_format
        custom_field.easy_computed_token = evaluator.computed_token
      end
    end

  end

  factory :easy_custom_field_group, parent: :enumeration, class: 'EasyCustomFieldGroup' do
    sequence(:name) { |n| "Easy CF Group ##{n}" }
  end
end
