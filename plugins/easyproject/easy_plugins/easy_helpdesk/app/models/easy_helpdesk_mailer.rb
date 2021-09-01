class EasyHelpdeskMailer < EasyExternalMailer

  def received_support_ticket(issue, mail_template)
    @html_body = mail_template.body_html
    if issue.maintained_by_easy_helpdesk?
      @html_body = issue.maintained_easy_helpdesk_project.email_header + @html_body unless issue.maintained_easy_helpdesk_project.email_header.blank?
      @html_body = @html_body + issue.maintained_easy_helpdesk_project.email_footer unless issue.maintained_easy_helpdesk_project.email_footer.blank?
    end

    @html_body = issue.easy_helpdesk_replace_tokens(@html_body, nil, mail_template)
    @text_body = issue.easy_helpdesk_replace_tokens(mail_template.body_plain, nil, mail_template)
    subject = issue.easy_helpdesk_replace_tokens(mail_template.subject, nil, mail_template)

    references(issue)

    mailbox = mail_template.mailboxes.first

    mail_options = {}

    custom_sender = EasySetting.value('easy_helpdesk_allow_custom_sender') && EasySetting.value('easy_helpdesk_custom_sender', issue.project, false)
    mailbox_sender = mailbox.sender_mail.to_s.strip if mailbox

    mail_options[:from] = custom_sender.presence || mailbox_sender
    mail_options[:reply_to] = mailbox_sender
    mail_options[:to] = mail_template.send_to
    mail_options[:cc] = mail_template.send_cc
    mail_options[:subject] = subject

    mail(mail_options)
  end

end
