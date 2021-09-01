FactoryBot.define do
  factory :test_plan do
    sequence(:name) { |n| "Test plan #{n}" }
    association :author, factory: :user
    project

    trait :with_test_cases do
      transient do
        number_of_test_cases { 3 }
      end
      after :create do |test_plan, evaluator|
        test_plan.test_cases = FactoryBot.create_list :test_case, evaluator.number_of_test_cases, project: test_plan.project
      end
    end

    factory :test_plan_with_test_cases do
      with_test_cases
    end
  end

  factory :test_case do
    sequence(:name) {|n| "Test case #{n}"}
    scenario { 'Scenario 1' }
    expected_result { 'Expected result
Working properly
Working partially
Missing feature
Horrible Bugs' }
    association :author, factory: :user
    project

    trait :with_issues do
      transient do
        number_of_issues { 3 }
      end
      after :create do |test_case, evaluator|
        test_case.issues = FactoryBot.create_list :issue, evaluator.number_of_issues, project: test_case.project

      end
    end

    trait :with_executions_with_attachments do
      transient do
        number_of_executions { 3 }
      end
      after :create do |test_case, evaluator|
        test_case.test_case_issue_executions = FactoryBot.create_list :test_case_issue_execution_with_attachments, evaluator.number_of_executions, test_case: test_case
      end
    end

    trait :with_attachments do
      transient do
        number_of_attachments { 3 }
      end
      after :create do |test_case, evaluator|
        test_case.attachments = FactoryBot.create_list :attachment, evaluator.number_of_attachments, container: test_case
      end
    end

    factory :test_case_with_issues_with_executions_with_attachments do
      with_issues
      with_executions_with_attachments
      with_attachments
    end
  end

  factory :test_case_issue_execution do
    association :test_case, :with_issues
    issue { test_case.issues.to_a[rand(test_case.issues.count)]}
    association :author, factory: :user

    trait :with_attachments do
      transient do
        number_of_attachments { 3 }
      end
      after :create do |tc_issue_execution, evaluator|
        tc_issue_execution.attachments = FactoryBot.create_list :attachment, evaluator.number_of_attachments, container: tc_issue_execution
      end
    end

    factory :test_case_issue_execution_with_attachments do
      with_attachments
    end
  end

  factory :project_with_test_cases, parent: :project do
    transient do
      number_of_test_cases { 3 }
    end

    after :create do |project, evaluator|
      project.test_cases = FactoryBot.create_list :test_case_with_issues_with_executions_with_attachments, evaluator.number_of_test_cases, project: project
    end
  end

  factory :project_with_test_plans, parent: :project do
    transient do
      number_of_test_plans { 3 }
    end
    after :create do |project, evaluator|
      project.test_plans = FactoryBot.create_list :test_plan_with_test_cases, evaluator.number_of_test_plans, project: project
    end
  end

  factory :test_case_easy_entity_import, class: 'EasyEntityImport' do
    sequence(:name) { |n| "Import ##{n}" }
    entity_type { "TestCase" }
  end

  factory :test_case_easy_entity_import_attributes_assignment, class: 'EasyEntityImportAttributesAssignment', aliases: [:test_case_import_assignment] do
    easy_entity_import factory: :test_case_easy_entity_import
  end

  factory :easy_test_case_csv_import do
    sequence(:name) { |n| "EasyTestCaseCsvImport #{n}" }
    entity_type { "TestCase" }
  end
end
