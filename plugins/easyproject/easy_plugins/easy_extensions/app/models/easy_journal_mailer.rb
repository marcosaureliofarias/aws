class EasyJournalMailer < Mailer
  helper AvatarsHelper

  def self.deliver_mentioned(recipients, journal)
    recipients.each do |recipient|
      user_mentioned(recipient, journal).deliver_later
    end
  end

  def user_mentioned(recipient, journal)
    @journal    = journal
    @user       = journal.user
    @entity     = journal.journalized
    @entity_url = polymorphic_url(@entity)

    if @entity.is_a?(Issue)
      redmine_headers 'Project'  => @entity.project.identifier,
                      'Issue-Id' => @entity.id
      redmine_headers 'Issue-Author' => @entity.author.login if @entity.author
      redmine_headers 'Issue-Assignee' => @entity.assigned_to.login if @entity.assigned_to
    end

    message_id @journal
    references @entity

    mail to: recipient, subject: l(:label_mentioned_email_subject, entity_title: @entity.to_s)
  end

end