module RedmineTestCases
  module EpmPieChartQueryPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        
      end
    end

    module InstanceMethods
      
      def available_for_queries
        super + ['TestCaseQuery', 'TestCaseIssueExecutionQuery']
      end
      
    end

    module ClassMethods

    end

  end

end
RedmineExtensions::PatchManager.register_model_patch 'EpmPieChartQuery', 'RedmineTestCases::EpmPieChartQueryPatch'
