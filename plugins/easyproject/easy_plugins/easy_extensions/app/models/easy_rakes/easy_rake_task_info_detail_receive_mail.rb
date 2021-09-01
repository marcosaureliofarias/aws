class EasyRakeTaskInfoDetailReceiveMail < EasyRakeTaskInfoDetail

  STATUS_UNKNOWN                          = 0
  STATUS_RECEIVED                         = 1
  STATUS_PROCESSED_AND_DELETED            = 2
  STATUS_NOT_PROCESSED_AND_DELETED        = 3
  STATUS_NOT_PROCESSED_AND_LEFT_ON_SERVER = 4
  STATUS_CANNOT_BE_PROCESSED              = 5

  def self.status_caption(status)
    case status
    when STATUS_UNKNOWN
      l(:'easy_rake_task_info_details.receive_mail.status.unknown')
    when STATUS_RECEIVED
      l(:'easy_rake_task_info_details.receive_mail.status.received')
    when STATUS_PROCESSED_AND_DELETED
      l(:'easy_rake_task_info_details.receive_mail.status.processed_and_deleted')
    when STATUS_NOT_PROCESSED_AND_DELETED
      l(:'easy_rake_task_info_details.receive_mail.status.not_processed_and_deleted')
    when STATUS_NOT_PROCESSED_AND_LEFT_ON_SERVER
      l(:'easy_rake_task_info_details.receive_mail.status.not_processed_and_left_on_server')
    when STATUS_CANNOT_BE_PROCESSED
      l(:'easy_rake_task_info_details.receive_mail.status.cannot_be_processed')
    end
  end

  def detail_url(task = nil)
    { :controller => 'easy_rake_tasks', :action => 'easy_rake_task_info_detail_receive_mail', :id => task, :easy_task_info_detail_id => self }
  end

  def caption
    @caption ||= self.email ? Redmine::CodesetUtil.replace_invalid_utf8(@email.subject).to_s : self.email_attachment.try(:filename).to_s
  end

  def status_caption
    self.class.status_caption(self.status)
  end

  def email_attachment
    @email_attachment ||= self.reference
  end

  def email_attachment_content
    return nil if self.email_attachment.nil?
    @email_attachment_content ||= File.binread(self.email_attachment.diskfile) if File.exist?(self.email_attachment.diskfile)
  end

  def email
    return nil if self.email_attachment_content.nil?
    @email = Mail.new(self.email_attachment_content)
  end

end
