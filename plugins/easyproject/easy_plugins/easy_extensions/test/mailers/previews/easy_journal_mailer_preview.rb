class EasyJournalMailerPreview < ActionMailer::Preview

  def user_mentioned
    commenter = User.new(id: 1, login: "commenter", firstname: "User", lastname: "Commenter", mail: "commenter@easy.cz")
    recipient = User.new(id: 2, login: "recipient", firstname: "User", lastname: "Recipient", mail: "recipient@easy.cz")
    project = Project.new(id: 1, identifier: "xxx", name: "Super development", created_on: Time.now)
    issue = Issue.new id: 1, project: project, subject: "Preview ISSUE", tracker: Tracker.new(id: 1, name: "Task"), assigned_to: commenter, author: commenter, status: IssueStatus.last, created_on: Time.now
    journal = Journal.new(id: 1, journalized: issue, user: commenter, notes: "@recipient, I mention you!", created_on: Time.now)
    EasyJournalMailer.user_mentioned(recipient, journal)
  end

end