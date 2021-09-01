class TestCaseIssueExecutionResult < Enumeration
  acts_as_easy_translate

  has_many :test_case_issue_executions, foreign_key: 'result_id'

  OptionName = :enumeration_test_case_execution_result

  def option_name
    OptionName
  end

  def objects_count
    test_case_issue_executions.count
  end
end
