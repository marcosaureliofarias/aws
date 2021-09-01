class EasyCrmMailHandler < EasyMailHandler

  attr_accessor :easy_crm_project

  def dispatch_to_default
    receive_easy_crm_case
  end

  def receive_easy_crm_case
    project = handler_options[:easy_rake_task].project if handler_options[:easy_rake_task]

    easy_crm_case = EasyCrmCase.new(:author => self.user, :project => project)
    easy_crm_case.easy_crm_case_status = EasyCrmCaseStatus.default
    easy_crm_case.name = cleaned_up_subject
    if easy_crm_case.name.blank?
      easy_crm_case.name = '(no subject)'
    end
    easy_crm_case.description = cleaned_up_text_body
    mails = mails_from_and_cc(self.email)
    easy_crm_case.email = mails[:to]
    easy_crm_case.email_cc = mails[:cc]
    easy_crm_case.need_reaction = true

    callback_receive_easy_crm_case_before_save(easy_crm_case)

    if handler_options[:no_issue_validation]
      easy_crm_case.save(:validate => false)
    else
      easy_crm_case.save!
    end

    add_attachments(easy_crm_case)

    save_email_as_eml(easy_crm_case)

    log_info_msg "#{self.class.name}: issue ##{easy_crm_case.id} created by #{self.user}"

    callback_receive_easy_crm_case_after_save(easy_crm_case)

    easy_crm_case
  end

  def receive_easy_crm_case_reply(easy_crm_case_id, from_journal=nil)
    easy_crm_case = EasyCrmCase.where(:id => easy_crm_case_id).first
    return unless easy_crm_case
    # check permission
    unless handler_options[:no_permission_check]
      unless easy_crm_case.editable?(self.user)
        raise UnauthorizedAction
      end
    end

    # ignore CLI-supplied defaults for new easy_crm_cases
    # handler_options[:easy_crm_case].clear

    journal = easy_crm_case.init_journal(self.user)
    if from_journal && from_journal.private_notes?
      # If the received email was a reply to a private note, make the added note private
      easy_crm_case.private_notes = true
    end
    #easy_crm_case.safe_attributes = issue_attributes_from_keywords(easy_crm_case)
    #easy_crm_case.safe_attributes = {'custom_field_values' => custom_field_values_from_keywords(easy_crm_case)}
    journal.notes = cleaned_up_text_body

    easy_crm_case.need_reaction = true

    callback_receive_easy_crm_case_reply_before_save(easy_crm_case, journal)

    easy_crm_case.save!
    add_attachments(easy_crm_case)

    save_email_as_eml(journal.journalized)

    log_info_msg "#{self.class.name}: easy_crm_case #{easy_crm_case.id} updated by #{self.user}"

    callback_receive_easy_crm_case_reply_after_save(easy_crm_case, journal)

    journal
  end

  def receive_journal_reply(journal_id)
    journal = Journal.find_by(id: journal_id)
    if journal && journal.journalized_type == 'EasyCrmCase'
      receive_easy_crm_case_reply(journal.journalized_id, journal)
    end
  end

  def accept_attachment?(attachment)
    !attachment.inline? && super(attachment)
  end

  def callback_receive_easy_crm_case_before_save(easy_crm_case)
  end

  def callback_receive_easy_crm_case_after_save(easy_crm_case)
  end

  def callback_receive_easy_crm_case_reply_before_save(easy_crm_case, journal)
  end

  def callback_receive_easy_crm_case_reply_after_save(easy_crm_case, journal)
  end

end
