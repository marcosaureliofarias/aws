class EasyJob::MailerTask < EasyJob::Task

  def perform(message)
    case message
    when ActionMailer::MessageDelivery
      # Generate mail and send it
      message.deliver_now
    when Mail::Message
      # Already generated, just send it
      message.deliver
    end
  end

end
