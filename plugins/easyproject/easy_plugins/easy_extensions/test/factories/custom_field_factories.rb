FactoryGirl.define do

  factory :custom_field do
    transient do
      projects { [] }
      trackers { [] }
    end

    sequence(:name) { |n| "Any CF ##{n}" }
    field_format { 'string' }
    min_length { 1 }
    max_length { 10 }
    is_required { false }
    is_for_all { true }
    is_filter { true }
    searchable { true }

    after :build do |custom_field, evaluator|
      custom_field.project_ids = (custom_field.project_ids + evaluator.projects) if evaluator.projects.is_a?(Array) && evaluator.projects.any?
      custom_field.tracker_ids += evaluator.trackers.collect { |tracker|
        if tracker.is_a? Numeric;
          tracker
        else
          tracker.id;
        end } if evaluator.trackers.any?
    end

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
        custom_field.easy_computed_token                    = evaluator.computed_token
      end
    end

  end

  factory :issue_custom_field, :parent => :custom_field, :class => 'IssueCustomField' do

    trait :external_mails do
      field_format { 'email' }
      non_deletable { true }
      internal_name { 'external_mails' }
      show_on_more_form { false }
      min_length { nil }
      max_length { nil }
    end

    trait :as_value_tree do
      field_format { 'value_tree' }
      is_filter { true }
      possible_values { [
          'Value 1',
          '> Value 1.1',
          '> Value 1.2',
          'Value 2'
      ] }
    end

    factory :external_mails_issue_custom_field, :traits => [:external_mails]
  end

  factory :attachment_custom_field, :parent => :custom_field, :class => 'AttachmentCustomField' do
    sequence(:name) { |n| "Attachment CF ##{n}" }
    is_filter { false }
  end

  factory :project_custom_field, :parent => :custom_field, :class => 'ProjectCustomField' do
    sequence(:name) { |n| "Project CF ##{n}" }
    is_for_all { true }
    show_on_list { true }
  end

  factory :user_custom_field, :parent => :custom_field, :class => 'UserCustomField' do
    sequence(:name) { |n| "User CF ##{n}" }
  end

  factory :version_custom_field, :parent => :custom_field, :class => 'VersionCustomField' do
    sequence(:name) { |n| "Version CF ##{n}" }
  end

  factory :time_entry_custom_field, :parent => :custom_field, :class => 'TimeEntryCustomField' do
    sequence(:name) { |n| "User CF ##{n}" }
  end

end
