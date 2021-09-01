class EasyRakeTaskEasyHelpdeskReceiveMail < EasyRakeTaskReceiveIssueMail

  has_and_belongs_to_many :mail_templates, :class_name => 'EasyHelpdeskMailTemplate', :join_table => 'easy_helpdesk_mail_templates_mailboxes', :foreign_key => 'mailbox_id', :association_foreign_key => 'mail_template_id'
  has_one :default_for_helpdesk_project, :class_name => 'EasyHelpdeskProject', :foreign_key => 'default_for_mailbox_id'

  def self.find_by_username(mailbox_username)
    return nil if mailbox_username.blank?
    EasyRakeTaskEasyHelpdeskReceiveMail.active.to_a.detect{|m| m.sender_mail.to_s.strip.casecmp(mailbox_username.strip).zero?}
  end

  def self.find_mailboxes_non_default
    EasyRakeTaskEasyHelpdeskReceiveMail.includes(:default_for_helpdesk_project).where(:easy_helpdesk_projects => {:id => nil})
  end

  def create_default_options_from_settings(s)
    options = super(s)

    options[:mail_handler_klass] = 'EasyHelpdeskMailHandler'

    if EasySetting.value('easy_helpdesk_allow_override')
      options[:allow_override] = EasyHelpdesk.override_attributes.join(',')
    end

    options[:skip_ignored_emails_headers_check] = settings['skip_ignored_emails_headers_check'].presence || (EasySetting.value('easy_helpdesk_skip_ignored_emails_headers_check') == true ? '1' : nil)

    options
  end

  def visible?
    User.current.allowed_to_globally?(:manage_easy_helpdesk, {})
  end

  def additional_task_info_view_path
    'easy_rake_tasks/additional_task_info/easy_rake_task_easy_helpdesk_receive_mail'
  end

  def category_caption_key
    :easy_helpdesk_name
  end

  def registered_in_plugin
    :easy_helpdesk
  end

end
