class ExpectedResultToEnumeration < EasyExtensions::EasyDataMigration
  def up
    rpass = TestCaseIssueExecutionResult.create(name: 'Pass', active: true)
    rfail = TestCaseIssueExecutionResult.create(name: 'Fail', active: true)

    TestCaseIssueExecution.where('result IS NOT NULL').find_each do |ex|
      ex.result_id = ex.pass? ? rpass.id : rfail.id
      ex.save!
    end
  end
end
