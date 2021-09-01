FactoryBot.define do
  factory :computed_issue_from_query_custom_field, parent: :issue_custom_field, class: 'IssueCustomField' do
    field_format { 'easy_computed_from_query' }
    settings { {
                 'associated_query' => 'EasyIssueQuery',
                 'easy_query_formula' => 'min',
                 'easy_query_column' => 'start_date',
                 'easy_query_filters' => {'set_filter' => '1'}
             } }
  end

  # easy computed custom_fields
  factory :rys_ccfff_computed_issue_custom_field, parent: :issue_custom_field, class: 'IssueCustomField' do
    transient do
      computed_format { 'int' }
      computed_token { '%{issue_id}' }
    end

    field_format { 'easy_computed_token' }

    after(:build) do |custom_field, evaluator|
      custom_field.easy_computed_token_format = evaluator.computed_format
      custom_field.easy_computed_token = evaluator.computed_token
    end
  end

  # easy crm
  factory :rys_ccfff_easy_crm_case_status, class: 'EasyCrmCaseStatus' do
    sequence(:name) { |n| "Test crm status ##{n}" }
  end
end
