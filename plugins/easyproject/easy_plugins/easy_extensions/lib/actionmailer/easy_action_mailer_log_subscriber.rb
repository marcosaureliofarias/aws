module ActionMailer
  class EasyLogSubscriber < LogSubscriber
    def deliver(event)
      info("Sent email: #{log_email_hash(event).to_json}")
    end

    def log_email_hash(event)
      {
          subject: event.payload[:subject],
          to:      Array(event.payload[:to]).join(", "),
          cc:      Array(event.payload[:cc]).join(", "),
          bcc:     Array(event.payload[:bcc]).join(", "),
          from:    Array(event.payload[:from]).first
      }
    end

    def logger
      Logger.new(File.join(Rails.root, 'log', 'easy_mailer.log'))
    end
  end
end
