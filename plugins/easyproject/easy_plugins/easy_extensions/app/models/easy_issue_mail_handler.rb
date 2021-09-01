class EasyIssueMailHandler < EasyMailHandler

  def receive_issue
    project = target_project
    # check permission
    unless handler_options[:no_permission_check]
      raise MailHandler::UnauthorizedAction unless self.user.allowed_to?(:add_issues, project)
    end

    issue      = Issue.new(author: self.user, project: project)
    callback_receive_issue_after_build(issue)
    attributes = issue_attributes_from_keywords(issue) || {}
    if handler_options[:no_permission_check]
      issue.tracker_id = attributes['tracker_id'] if attributes.has_key?('tracker_id')
      if issue.project
        issue.tracker_id ||= issue.project.trackers.first.try(:id)
      end
    end

    issue.safe_attributes = attributes
    custom_field_values   = custom_field_values_from_keywords(issue)

    issue.subject = Redmine::CodesetUtil.replace_invalid_utf8(cleaned_up_subject).to_s

    issue.description = email_body
    issue.start_date  ||= User.current.today if Setting.default_issue_start_date_to_creation_date?
    issue.is_private  = (handler_options[:issue][:is_private] == '1')

    callback_receive_issue_before_save(issue)

    if issue.project && issue.tracker
      core_fields = issue.tracker.core_fields
      unless core_fields.include?('easy_email_to')
        issue.tracker.core_fields = core_fields.concat(['easy_email_to', 'easy_email_cc'])
        issue.tracker.save
      end

      mails               = mails_from_and_cc(self.email)
      issue.easy_email_to = mails[:to]
      issue.easy_email_cc = mails[:cc]
    end
    issue.safe_attributes = { 'custom_field_values' => custom_field_values }

    # add To and Cc as watchers before saving so the watchers can reply to Redmine
    add_watchers(issue)

    if handler_options[:no_issue_validation]
      issue.save(:validate => false)
    else
      issue.save!
    end

    issue_spent_time_from_keywords(issue)
    add_attachments(issue)
    save_email_as_eml(issue)

    log_info_msg "#{self.class.name}: issue ##{issue.id} created by #{self.user}"

    callback_receive_issue_after_save(issue)
    issue
  end

  def receive_issue_reply(issue_id, from_journal = nil)
    issue = Issue.find_by(:id => issue_id)
    return unless issue
    # check permission
    unless handler_options[:no_permission_check]
      unless issue.editable?(self.user)
        raise UnauthorizedAction
      end
    end

    # ignore CLI-supplied defaults for new issues
    handler_options[:issue] = {}

    journal = issue.init_journal(self.user)
    if from_journal && from_journal.private_notes?
      # If the received email was a reply to a private note, make the added note private
      issue.private_notes = true
    end
    issue.safe_attributes = issue_attributes_from_keywords(issue)
    issue.safe_attributes = { 'custom_field_values' => custom_field_values_from_keywords(issue) }

    issue.easy_email_cc = all_mails_cc_array(email, issue).join(', ')
    issue_spent_time_from_keywords(issue)

    # add To and Cc as watchers before saving so the watchers can reply to Redmine
    add_watchers(issue)
    add_attachments(issue)

    save_email_as_eml(journal.journalized)

    journal.notes = email_body

    callback_receive_issue_reply_before_save(issue, journal)

    if handler_options[:no_issue_validation]
      issue.save(:validate => false)
    else
      issue.save!
    end

    log_info_msg "#{self.class.name}: issue ##{issue.id} updated by #{self.user}"

    callback_receive_issue_reply_after_save(issue, journal)

    journal
  end

  def callback_receive_issue_before_save(issue)
  end

  def callback_receive_issue_after_save(issue)
  end

  def callback_receive_issue_reply_before_save(issue, journal)
  end

  def callback_receive_issue_reply_after_save(issue, journal)
  end

  def callback_receive_issue_after_build(issue)
  end

  def email_contains_images?
    self.email.all_parts.any? { |p| p.content_id.present? && /image\/(.+)/.match?(p.mime_type) }
  end

  def email_body
    ((Setting.text_formatting == 'HTML') && email_contains_images?) ? cleaned_up_html_body(self.email) : cleaned_up_text_body
  end

  def prepare_html_body(attached_email)
    return cleaned_up_text_body unless attached_email.is_a?(Attachment)

    attachment = attached_email.current_version
    html_parts = self.email.all_parts.select { |part| part.mime_type == 'text/html' && !(part.header[:content_disposition].try(:disposition_type) == 'attachment') }

    if html_parts.any?
      @plain_text_body = html_parts.map do |p|
        body     = p.body.decoded
        encoding = pick_encoding(p)
        begin
          convert_to_utf8(body, encoding)
        rescue *Redmine::CodesetUtil::ENCODING_EXCEPTIONS
          Rails.logger.warn "ENCODING #{encoding} isn't supported"
          Redmine::CodesetUtil.replace_invalid_utf8(body)
        end
      end.join("\r\n")

      inline_image_replacement = " attachment:#{attachment.filename} "

      body_to_parse = Nokogiri::HTML.parse(@plain_text_body).at('body')
      body_to_parse.css('img').each { |tag| tag.replace(inline_image_replacement) }
      body_to_parse.css('style, script').each { |node| node.remove }

      sanitize(body_to_parse.to_s, :tags => ['p', 'a', 'br'])
    else
      plain_text_body
    end
  end

  def issue_spent_time_from_keywords(issue)
    return unless (handler_options[:no_permission_check] || user.allowed_to?(:log_time, issue.project))
    time_spent = get_keyword(:spent_time, override: true)
    if time_spent
      hours_minutes = time_spent.match(/(\d+)[^\d]*(\d*)/)[1..2]
      received      = email.received.reverse
      received      = received.detect { |x| x.try(:date_time) } || received.first
      activity      = TimeEntryActivity.default || TimeEntryActivity.first
      if received.respond_to?(:date_time) && activity
        time_entry                 = TimeEntry.new
        time_entry.user            = user
        time_entry.safe_attributes = {
            'spent_on'     => received.date_time.to_date,
            'hours_hour'   => hours_minutes[0],
            'hours_minute' => hours_minutes[1],
            'project_id'   => issue.project_id,
            'activity_id'  => activity.id,
            'issue_id'     => issue.id
        }
        time_entry.save(validate: false)
      end
    end
  end

  def accept_attachment?(attachment)
    !attachment.inline? && super(attachment)
  end

  def cleaned_up_html_body(attached_email)
    @cleaned_up_html_body ||= cleanup_body(prepare_html_body(attached_email))
  end
end
