module EasyExtensions
  class EasyMailTemplate

    attr_accessor :mail_sender, :mail_reply_to, :mail_replies_to, :mail_recepient, :mail_cc,
                  :mail_subject, :mail_body_html, :mail_body_plain,
                  :email_header, :email_footer,
                  :entity_url

    def self.get_external_emails_from_entity(entity)
      raise NotImplementedError
    end

    def self.get_easy_email_cc_from_entity(entity)
    end

    def self.from_params(params)
      t                 = new
      t.mail_sender     = params[:mail_sender]
      t.mail_reply_to   = params[:mail_reply_to]
      t.mail_replies_to = []
      t.mail_recepient  = params[:mail_recepient]
      t.mail_cc         = params[:mail_cc]
      t.mail_subject    = params[:mail_subject]
      t.mail_body_html  = params[:mail_body_html] unless Setting.plain_text_mail?
      t.mail_body_plain = params[:mail_body_plain] if Setting.plain_text_mail?
      t
    end

    def self.from_entity(entity)
      t             = new
      t.mail_sender = User.current.mail_with_name
      #t.mail_reply_to = Setting.mail_from
      t.mail_recepient = get_external_emails_from_entity(entity)
      t.mail_cc        = get_easy_email_cc_from_entity(entity)
      t
    end

    def mail_body_html=(value)
      unless Setting.plain_text_mail?
        #self.mail_body_plain = ReverseMarkdown.parse(value) if self.mail_body_plain.blank?
        self.mail_body_plain = value&.dup
      end

      @mail_body_html = value
    end

  end
end
