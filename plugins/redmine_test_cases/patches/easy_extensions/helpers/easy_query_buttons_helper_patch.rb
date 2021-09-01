module RedmineTestCases
  module EasyQueryButtonsHelperPatch

    def self.included(base)
      base.class_eval do

        def test_plan_query_additional_ending_buttons(entity, options = {})
          @test_case_formatter ||= TestPlanFormatter.new(self)
          @test_case_formatter.ending_buttons(entity)
        end

        def test_case_query_additional_ending_buttons(entity, options = {})
          @test_case_formatter ||= TestCaseFormatter.new(self)
          @test_case_formatter.ending_buttons(entity)
        end

        def test_case_issue_execution_query_additional_ending_buttons(entity, options = {})
          @test_case_issue_execution_formatter ||= TestCaseIssueExecutionFormatter.new(self)
          @test_case_issue_execution_formatter.ending_buttons(entity)
        end

        def test_case_csv_import_query_additional_ending_buttons(entity, options = {})
          @test_case_formatter ||= TestCaseCsvImportFormatter.new(self)
          @test_case_formatter.ending_buttons(entity)
        end

      end
    end

  end
end

RedmineExtensions::PatchManager.register_helper_patch 'EasyQueryButtonsHelper', 'RedmineTestCases::EasyQueryButtonsHelperPatch', if: proc {Redmine::Plugin.installed? :easy_extensions}
