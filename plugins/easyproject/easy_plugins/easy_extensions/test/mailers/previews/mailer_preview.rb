# Preview all emails at http://localhost:3000/rails/mailers/
class MailerPreview < ActionMailer::Preview

  def send_mail_issue_add
    User.current.as_admin do
      Mailer.issue_add(Issue.find(70807), { :to => ['milos@easy.cz'], :cc => [] })
    end
  end

  def send_mail_issue_edit
    User.current.as_admin do
      Mailer.issue_edit(User.current, Issue.first.journals.last)
    end
  end

  def document_added
    User.current.as_admin do
      Mailer.document_added(Document.last)
    end
  end

  def test_email
    User.current.as_admin do
      Mailer.test_email(User.current)
    end
  end

  def attachments_added
    User.current.as_admin do
      Mailer.attachments_added(Attachment.first(2))
    end
  end

  def news_added
    User.current.as_admin do
      Mailer.news_added(News.last)
    end
  end

  # def news_comment_added
  #   User.current.as_admin do
  #     Mailer.news_comment_added(Comment.last) #
  #   end
  # end

  def message_posted
    User.current.as_admin do
      Mailer.message_posted(Message.last)
    end
  end

  # def wiki_content_added
  #   User.current.as_admin do
  #     Mailer.wiki_content_added(Wiki.last)
  #   end
  # end

  #wiki_content_updated
  #account_information
  #account_activation_request
  #account_activated
  #lost_password
  #register

end
