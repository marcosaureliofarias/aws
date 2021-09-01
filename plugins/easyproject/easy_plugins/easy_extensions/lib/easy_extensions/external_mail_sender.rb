module EasyExtensions
  class ExternalMailSender
    include Redmine::I18n

    attr_reader :entity, :mail_template, :journal, :attachments

    def initialize(entity, mail_template, options = {})
      @entity        = entity
      @mail_template = mail_template
      @journal       = options[:journal] if options.present?
      @attachments   = options[:attachments] if options.present?
    end

    def self.call(entity, mail_template, options = {})
      service = new(entity, mail_template, options)
      return false unless service.valid?
      service.create_journal
      email = service.send_email
      service.attach_email(email) if email
      entity.save
      service
    end

    def valid?
      mail_template.mail_recepient.present?
    end

    def create_journal
      if entity.respond_to? :init_journal
        entity.clear_current_journal if entity.current_journal.present?
        entity.init_journal(User.current, l(:text_external_email_sent, email: mail_template.mail_recepient))
        entity.current_journal.private_notes = true
      end
    end

    def send_email
      return nil unless valid?
      email = EasyExternalMailer.easy_external_mail(mail_template, entity, @journal, @attachments)
      email.deliver
      email
    end

    def attach_email(email)
      return if entity.attachments_delegable?

      tmp_file = EasyUtils::FileUtils.save_email_to_file(email, false)
      return unless tmp_file.present?

      begin
        a             = Attachment.new(file: tmp_file, author: User.current)
        a.container   = entity
        a.filename    = "#{Redmine::CodesetUtil.to_utf8(email.subject.to_s, email.charset)}.eml"
        a.description = a.filename if a.description_required?
        if a.valid?
          entity.attachments << a
        else
          entity.unsaved_attachments << a
        end
      ensure
        tmp_file.close
      end
    end

  end
end
