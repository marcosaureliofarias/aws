module RedmineTestCases
  module ProjectPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        has_many :test_plans, dependent: :destroy
        has_many :test_cases, dependent: :destroy
        has_many :test_case_issue_executions, through: :test_cases
      end
    end

    module InstanceMethods

      def copy_test_cases(project, options={})
        issues_map = options[:issues_map] || {}

        test_plans_map = {}
        project.test_plans.each do |test_plan|
          new_test_plan = TestPlan.new
          new_test_plan.copy_from(test_plan, options)
          new_test_plan.project = self
          new_test_plan.save(validate: false)
          test_plans_map[test_plan.id] = new_test_plan
        end

        project.test_cases.each do |test_case|
          new_test_case = TestCase.new
          new_test_case.copy_from(test_case, options)
          new_test_case.project = self
          test_case.test_plans.each do |test_plan|
            new_test_plan = test_plans_map[test_plan.id]
            new_test_case.test_plans << new_test_plan if new_test_plan
          end

          test_case.issues.each do |issue|
            new_issue = issues_map[issue.id]
            new_test_case.issues << new_issue.reload if new_issue
          end
          new_test_case.save(validate: false)

          test_case.attachments.each do |at|
            at_copy = at.copy
            at_copy.container_id = new_test_case.id
            at_copy.save(validate: false)
          end

          new_test_case.copy_test_case_issue_executions(test_case, options)
        end
      end

    end

    module ClassMethods

    end

  end

end
RedmineExtensions::PatchManager.register_model_patch 'Project', 'RedmineTestCases::ProjectPatch'
