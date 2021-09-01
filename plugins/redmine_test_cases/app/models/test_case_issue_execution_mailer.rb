class TestCaseIssueExecutionMailer < Mailer

  helper :test_case_issue_executions

  def self.deliver_test_case_issue_execution_added(test_case_issue_execution)
    users = test_case_issue_execution.notified_users
    users.each do |user|
      test_case_issue_execution_added(user, test_case_issue_execution).deliver
    end
  end

  def self.deliver_test_case_issue_execution_updated(test_case_issue_execution)
    users = test_case_issue_execution.notified_users
    users.each do |user|
      test_case_issue_execution_updated(user, test_case_issue_execution).deliver
    end
  end

  def test_case_issue_execution_added(user, test_case_issue_execution)
    @author = test_case_issue_execution.author
    @test_case_issue_execution = test_case_issue_execution
    @test_case_issue_execution_url = url_for(controller: 'test_case_issue_executions', action: 'show', id: test_case_issue_execution)

    message_id test_case_issue_execution
    references test_case_issue_execution

    mail to: user,
      subject: "#{l(:label_test_case_issue_execution)}: #{test_case_issue_execution.to_s}"
  end

  def test_case_issue_execution_updated(user, test_case_issue_execution)
    @author = test_case_issue_execution.author
    @test_case_issue_execution = test_case_issue_execution
    @test_case_issue_execution_url = url_for(controller: 'test_case_issue_executions', action: 'show', id: test_case_issue_execution)

    message_id test_case_issue_execution
    references test_case_issue_execution

    mail to: user,
      subject: "#{l(:label_test_case_issue_execution)}: #{test_case_issue_execution.to_s}"
  end

end
