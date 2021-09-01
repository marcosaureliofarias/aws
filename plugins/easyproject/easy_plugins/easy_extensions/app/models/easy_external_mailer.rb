class EasyExternalMailer < EasyBlockMailer

  layout 'easy_external_mailer'

  def easy_external_mail(mail_template, entity, journal = nil, all_attachments = [])
#    redmine_headers 'Issue-Id' => issue.id,
#      'Issue-Author' => issue.author.login
#    redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
    redmine_headers 'Project' => entity.project.identifier if entity.respond_to?(:project) && entity.project
    message_id(journal || entity)
    references entity

    process_attachments(mail_template, entity, all_attachments)

    @author              = (journal && journal.user) || (entity.respond_to?(:author) && entity.author) # redmine inner logic in "mail" function
    @force_notify_author = true
    @mail_template       = mail_template

    mail :to   => mail_template.mail_recepient, :cc => mail_template.mail_cc, :subject => mail_template.mail_subject,
         :from => mail_template.mail_sender, :reply_to => mail_template.mail_reply_to
  end

  def process_attachments(mail_template, entity, all_attachments = [])
    if all_attachments
      all_attachments.each do |att|
        attachments[att.filename] = IO.binread(att.diskfile)
      end
    end
  end

end
