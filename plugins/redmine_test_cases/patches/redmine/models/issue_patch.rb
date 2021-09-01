module RedmineTestCases
  module IssuePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        has_many :entity_assignments, :class_name => 'EasyEntityAssignment', :as => :entity_from, :dependent => :delete_all
        has_many :test_cases, -> { order(:name)}, :through => :entity_assignments, :source => :entity_to, :source_type => 'TestCase'
        has_many :test_plans, -> { order(:name)}, :through => :entity_assignments, :source => :entity_to, :source_type => 'TestPlan'

        has_many :test_case_issue_executions, dependent: :destroy

        safe_attributes 'test_case_ids', 'test_plan_ids'
      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end

  end

end
RedmineExtensions::PatchManager.register_model_patch 'Issue', 'RedmineTestCases::IssuePatch'
