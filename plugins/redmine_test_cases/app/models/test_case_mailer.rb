class TestCaseMailer < Mailer

  helper :test_cases

  def self.deliver_test_case_added(test_case)
    users = test_case.notified_users
    users.each do |user|
      test_case_added(user, test_case).deliver_later
    end
  end

  def self.deliver_test_case_updated(test_case)
    users = test_case.notified_users
    users.each do |user|
      test_case_updated(user, test_case).deliver_later
    end
  end

  def test_case_added(user, test_case)
    redmine_headers 'Project' => test_case.project.identifier

    @author = test_case.author
    @test_case = test_case
    @test_case_url = url_for(controller: 'test_cases', action: 'show', id: test_case)

    message_id test_case
    references test_case

    mail to: user,
      subject: "#{l(:label_test_case)}: #{test_case.to_s}"
  end

  def test_case_updated(user, test_case)
    redmine_headers 'Project' => test_case.project.identifier

    @author = test_case.author
    @test_case = test_case
    @test_case_url = url_for(controller: 'test_cases', action: 'show', id: test_case)

    message_id test_case
    references test_case

    mail to: user,
      subject: "#{l(:label_test_case)}: #{test_case.to_s}"
  end

end
