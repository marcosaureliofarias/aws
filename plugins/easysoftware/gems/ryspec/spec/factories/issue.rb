FactoryBot.define do

  factory :issue do
    # transient do
    #   factory_is_child false
    #   watchers []
    # end

    sequence(:subject) { |n| "Issue ##{n}" }
    project { FactoryBot.create(:project, number_of_issues: 0) }
    tracker { project.trackers.first }
    start_date { Date.today }
    due_date { Date.today + 7.days }
    status { tracker.default_status }
    priority { IssuePriority.default || FactoryBot.create(:issue_priority, :default) }

    author { FactoryBot.build(:user) }
    assigned_to { author }

    after(:create) do |issue, _|
      issue.reload
    end
  end

  factory :issue_custom_field, parent: :custom_field, class: 'IssueCustomField' do

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

    factory :external_mails_issue_custom_field, traits: [:external_mails]
  end

end
