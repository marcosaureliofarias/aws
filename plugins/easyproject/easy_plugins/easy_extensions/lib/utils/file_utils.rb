module EasyUtils
  class FileUtils

    def self.save_email_message_to_file(message, message_id, close_file = false)
      message = Mail.new(message) if !message.is_a?(Mail::Message)
      begin
        tmp_file = Tempfile.new(Attachment.disk_filename("#{message_id.to_s}.eml"), Rails.root.join('tmp').to_s)

        tmp_file.binmode
        tmp_file.write(message.to_s)
        tmp_file.rewind
        tmp_file.close if close_file
      rescue StandardError => e
        tmp_file = nil
        Rails.logger.error "EasyUtils::FileUtils.save_email_message_to_file -> cannot create tmp_file #{e.message}"
      end

      return tmp_file
    end

    def self.save_email_to_file(email, close_file = false)
      save_email_message_to_file(email, email.message_id, close_file)
    end

    def self.attach_email_to_entity(tmp_file, entity, attachment_file_name, author)
      author               ||= User.current
      attachment_file_name = if attachment_file_name.blank?
                               'Unknown subject'
                             else
                               attachment_file_name.strip[0, 251]
                             end
      a                    = nil
      begin
        a             = Attachment.new(:file => tmp_file, :author => author)
        a.container   = entity
        a.filename    = "#{attachment_file_name.to_s}.eml"
        a.description = a.filename if a.description_required?
        a.save
      ensure
        tmp_file.close
      end if tmp_file

      return a
    end

    def self.save_and_attach_email_message(message, message_id, entity, attachment_file_name, author)
      tmp_file = save_email_message_to_file(message, message_id, false)
      attach_email_to_entity(tmp_file, entity, attachment_file_name, author)
    end

    def self.save_and_attach_email(email, entity, attachment_file_name, author)
      tmp_file = save_email_to_file(email, false)
      attach_email_to_entity(tmp_file, entity, attachment_file_name, author)
    end

  end
end
