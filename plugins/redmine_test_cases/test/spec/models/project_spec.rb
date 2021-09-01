require 'easy_extensions/spec_helper'

describe Project do
  let(:project) { FactoryBot.create :project_with_test_cases, :add_modules => %w(test_cases) }
  let(:project_template) { project.create_project_templates(:copying_action => :creating_template, :copy_author => true)[:saved].first }

  let(:project2) { FactoryBot.create :project_with_test_plans, :add_modules => %w(test_cases) }
  let(:project2_template) { project2.create_project_templates(:copying_action => :creating_template, :copy_author => true)[:saved].first }

  it 'has test_cases' do
    expect(project.test_cases.count).to eq(3)
    project.test_cases.each do |test_case|
      expect(test_case.issues.count).to eq(3)
      expect(test_case.attachments.count).to eq(3)
      expect(test_case.test_case_issue_executions.count).to eq(3)
    end
  end

  it 'has test_plans' do
    expect(project2.test_cases.count).to eq(9)
    expect(project2.test_plans.count).to eq(3)
    project.test_plans.each do |test_plan|
      expect(test_plan.test_cases.count).to eq(3)
    end
  end

  it 'copy test cases' do
    expect(project_template.test_cases.count).to eq(3)
  end

  it 'copy test plans' do
    expect(project2_template.test_plans.count).to eq(3)
    expect(project2_template.test_cases.count).to eq(9)
  end

  it 'has issues' do
    project_template.test_cases.each do |test_case|
      expect(test_case.issues.count).to eq(3)
    end
  end

  it 'has attachments' do
    project_template.test_cases.each do |test_case|
      expect(test_case.attachments.count).to eq(3)
    end
  end

  it 'copy test case issue executions with attachments' do
    project_template.test_cases.each do |test_case|
      expect(test_case.test_case_issue_executions.count).to eq(3)
      test_case.test_case_issue_executions.each do |tc_issue_execution|
        expect(tc_issue_execution.attachments.count).to eq(3)
      end
    end
  end
end