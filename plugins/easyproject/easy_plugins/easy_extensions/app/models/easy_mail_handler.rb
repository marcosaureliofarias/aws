class EasyMailHandler < MailHandler
  attr_reader :instance_options

  STATUS_SUCCESSFUL   = 0
  STATUS_ERROR        = 1
  MAILER_DEAMON_REGEX = /\A.*MAILER-DAEMON.*\z/i

  def self.receive(raw_mail, options = {})
    easy_handler_options = {
        :easy_rake_task             => options[:easy_rake_task],
        :easy_rake_task_info_detail => options[:easy_rake_task_info_detail]
    }
    options              = options.deep_dup

    options[:issue] ||= {}

    options[:allow_override] ||= []
    if options[:allow_override].is_a?(String)
      options[:allow_override] = options[:allow_override].split(',')
    end
    options[:allow_override].map! { |s| s.strip.downcase.gsub(/\s+/, '_') }
    # Project needs to be overridable if not specified
    options[:allow_override] << 'project' unless options[:issue].has_key?(:project)

    options[:no_account_notice]   = (options[:no_account_notice].to_s == '1')
    options[:no_notification]     = (options[:no_notification].to_s == '1')
    options[:no_permission_check] = (options[:no_permission_check].to_s == '1')

    raw_mail.force_encoding('ASCII-8BIT')

    ActiveSupport::Notifications.instrument('receive.action_mailer') do |payload|
      mail = Mail.new(raw_mail)
      set_payload_for_mail(payload, mail)
      new.receive(mail, options.merge!(easy_handler_options))
    end
  end

  def receive(email, options = {})
    @handler_options = options
    @email           = email
    sender_email     = Array(email.from).first.to_s.strip

    # Ignore emails received from the application emission address to avoid hell cycles
    emission_address = Setting.mail_from.to_s.gsub(/(?:.*<|>.*|\(.*\))/, '').strip
    if sender_email.casecmp(emission_address) == 0
      log_info_msg "#{self.class.name}: ignoring email from Redmine emission address [#{sender_email}]"
      return STATUS_SUCCESSFUL
    end

    if !(handler_options.key?(:skip_ignored_emails_headers_check) && handler_options[:skip_ignored_emails_headers_check] == '1')
      if MAILER_DEAMON_REGEX.match?(sender_email)
        log_info_msg "#{self.class.name}: ignoring email from MAILER-DAEMON address [#{sender_email}]"
        return STATUS_SUCCESSFUL
      end

      # Ignore auto generated emails
      self.class.ignored_emails_headers.each do |key, ignored_value|
        value = email.header[key]
        if value
          value = value.to_s.downcase
          if (ignored_value.is_a?(Regexp) && ignored_value.match?(value)) || value == ignored_value
            log_info_msg "#{self.class.name}: ignoring email with #{key}:#{value} header"
            return STATUS_SUCCESSFUL
          end
        end
      end

      # TODO add to ignored_emails_headers like (\s*[2-9])
      if email.header['X-Loop-Detect'].to_s.to_i > 1
        log_info_msg "#{self.class.name}: ignoring email with X-Loop-Detect bigger than 1"
        return STATUS_SUCCESSFUL
      end
    end

    @user = User.having_mail(sender_email).first if sender_email.present?
    if @user && !@user.active?
      case handler_options[:unknown_user]
      when 'accept'
        @user = User.anonymous
      else
        @user = nil
      end
    end

    if @user.nil?
      # Email was submitted by an unknown user
      case handler_options[:unknown_user]
      when 'accept'
        @user = User.anonymous
      when 'create'
        @user = create_user_from_email
        if @user
          log_info_msg "#{self.class.name}: [#{@user.login}] account created"
          add_user_to_group(handler_options[:default_group])
          unless handler_options[:no_account_notice]
            ::Mailer.deliver_account_information(@user, @user.password)
          end
        else
          log_error_msg "#{self.class.name}: could not create account for [#{sender_email}]"
          return STATUS_ERROR
        end
      else
        @user = User.where(:login => handler_options[:unknown_user]).first unless handler_options[:unknown_user].blank?
        if @user.nil?
          # Default behaviour, emails from unknown users are ignored
          log_info_msg "#{self.class.name}: ignoring email from unknown user [#{sender_email}]"
          return STATUS_SUCCESSFUL
        end
      end
    end
    User.current = @user

    obj = dispatch

    if obj.is_a?(ActiveRecord::Base) && (easy_rake_task_info_detail = handler_options[:easy_rake_task_info_detail])
      easy_rake_task_info_detail.entity = obj
      easy_rake_task_info_detail.save
    end

    obj
  end

  def dispatch
    headers     = [email.in_reply_to, email.references].flatten.compact
    subject     = Redmine::CodesetUtil.replace_invalid_utf8(cleaned_up_subject).to_s
    first_error = nil

    if (matches = headers.map { |h| h.to_s =~ MESSAGE_ID_RE; [$1, $2.to_i] }).any?
      matches.each do |klass, object_id|
        method_name = "receive_#{klass}_reply"
        if respond_to?(method_name.to_sym, true)
          result = send method_name, object_id
          unless result
            first_error ||= MissingInformation.new("Unable to determine target #{klass} id: #{object_id}")
            next
          end
          return result
        else
          return dispatch_to_default
        end
      end
      raise first_error
    elsif m = subject.match(ISSUE_REPLY_SUBJECT_RE)
      unless receive_issue_reply(m[1].to_i)
        raise MissingInformation.new("Unable to determine target issue id: #{m[1].to_i}")
      end
      m
    elsif m = subject.match(MESSAGE_REPLY_SUBJECT_RE)
      unless receive_message_reply(m[1].to_i)
        raise MissingInformation.new("Unable to determine target message id: #{m[1].to_i}")
      end
      m
    else
      dispatch_to_default
    end
  rescue ActiveRecord::RecordInvalid => e
    # TODO: send a email to the user
    log_error_msg "#{self.class.name}: #{e.message}"
    STATUS_ERROR
  rescue MissingInformation => e
    log_error_msg "#{self.class.name}: missing information from #{user}: #{e.message}"
    STATUS_ERROR
  rescue UnauthorizedAction => e
    log_error_msg "#{self.class.name}: unauthorized attempt from #{user}"
    STATUS_ERROR
  end

  def save_email_as_eml(entity)
    filename = Redmine::CodesetUtil.replace_invalid_utf8(cleaned_up_subject).to_s.tr(' ', '_')
    EasyUtils::FileUtils.save_and_attach_email(self.email, entity, filename, User.current)
  end

  def cleaned_up_subject
    super.presence || '(no subject)'
  end

  def stripped_plain_text_body
    # strip html tags and remove doctype directive
    @stripped_plain_text_body ||= begin
      txt = strip_tags(cleaned_up_text_body.to_s.strip.gsub('<br>', "\r\n"))
      txt.sub! %r{^<!DOCTYPE .*$}, ''
      txt
    end
  end

  def add_attachments(obj)
    fix_attached_images_broken_filename

    if self.email.attachments && self.email.attachments.any?
      self.email.attachments.each do |attachment|
        next unless accept_attachment?(attachment)
        next unless attachment.body.decoded.size > 0

        create_or_update_attachment(obj, attachment)
      end
    end
  end

  # accept all attachments for rdm_mailhandler.rb cause the original eml isn't available
  #def accept_attachment?(attachment)
  #  !attachment.inline? && super(attachment)
  #end

  def create_or_update_attachment(obj, attachment)
    attachment_or_nothing = obj.get_existing_version(attachment.filename, {})

    if attachment_or_nothing
      attachment_or_nothing.attributes  = {
          :file      => attachment.body.decoded,
          :container => obj,
          :author    => self.user
      }
      attachment_or_nothing.description ||= attachment.filename if attachment_or_nothing.description_required?
      attachment_or_nothing.files_to_final_location
      attachment_or_nothing.save
      obj.after_new_version_create_journal(attachment_or_nothing)
    else
      attachment_or_nothing             = obj.attachments.build(
          :file         => attachment.body.decoded,
          :filename     => attachment.filename,
          :author       => self.user,
          :content_type => attachment.mime_type
      )
      attachment_or_nothing.description = attachment.filename if attachment_or_nothing.description_required?
      attachment_or_nothing.save
    end
  end

  def fix_attached_images_broken_filename
    self.email.all_parts.each do |part|
      if part.mime_type =~ /^image\/([a-z\-]+)$/
        file_extension = $1

        if part.filename.present? && part.filename =~ /\.$/
          # add missing file extension
          part.content_type        = part.content_type.gsub(/name=\"?.+\./, "\\0#{file_extension}") if part.content_type
          part.content_disposition = part.content_disposition.gsub(/filename=\"?.+\./, "\\0#{file_extension}") if part.content_disposition #(fixed_disposition)

        elsif part.filename.blank? && part.content_id.present? && part.content_id =~ /([a-z0-9\.]+)@/
          # create missing filename
          part.content_disposition = "inline; filename=\"#{$1}.#{file_extension}\""
        end
      end
    end
  end

  # Destructively extracts the value for +attr+ in +text+
  # Returns nil if no matching keyword found
  def extract_keyword!(text, attr, format = nil)
    keys = [attr.to_s.humanize]
    if attr.is_a?(Symbol)
      keys << l("field_#{attr}", :default => '', :locale => self.user.language) if self.user && self.user.language.present?
      keys << l("field_#{attr}", :default => '', :locale => Setting.default_language) if Setting.default_language.present?
    end
    keys.reject! { |k| k.blank? }
    keys.collect! { |k| Regexp.escape(k) }
    additional_keys = []
    keys.each do |key|
      key_without_diacritics = key.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n, '').to_s
      additional_keys << key_without_diacritics
      additional_keys << key_without_diacritics.downcase
      additional_keys << key_without_diacritics.upcase
      additional_keys << key.downcase
      additional_keys << key.upcase
    end
    keys.concat(additional_keys)
    keys.uniq!
    format ||= '.+'
    regexp = /^[ ]*(#{keys.join('|')})[ \t]*:[ \t]*(#{format})\s*$/i
    if m = text.match(regexp)
      keyword = m[2].strip
      text.sub!(regexp, '')
    end
    keyword
  end

  def get_keyword(attr, options = {})
    @keywords ||= {}
    if @keywords.has_key?(attr)
      @keywords[attr]
    else
      @keywords[attr] = begin
        override = options.key?(:override) ?
                       options[:override] :
                       (handler_options[:allow_override] & [attr.to_s.downcase.gsub(/\s+/, '_'), 'all']).present?

        if override && (v = extract_keyword!(stripped_plain_text_body, attr, options[:format]))
          v
        elsif !handler_options[:issue][attr].blank?
          handler_options[:issue][attr]
        end
      end
    end
  end

  def plain_text_body
    return @plain_text_body unless @plain_text_body.nil?
    @plain_text_body = email_parts_to_text(email.all_parts.select { |p| p.mime_type == 'text/plain' }).presence
    @plain_text_body ||= email_parts_to_text(email.all_parts.select { |p| p.mime_type == 'text/html' }).presence
    @plain_text_body ||= email_parts_to_text(email.text? ? [email] : []).presence if email.all_parts.empty?
    @plain_text_body ||= ''
  end

  def email_parts_to_text(parts)
    parts.reject! do |part|
      part.attachment?
    end

    formatting = Setting.text_formatting
    parts.map do |p|
      body         = p.body.decoded
      encoding     = pick_encoding(p)
      encoded_body = begin
        convert_to_utf8(body, encoding)
      rescue *Redmine::CodesetUtil::ENCODING_EXCEPTIONS
        Rails.logger.warn "ENCODING #{encoding} isn't supported"
        Redmine::CodesetUtil.replace_invalid_utf8(body)
      end

      # convert html parts to text
      text_body = if p.mime_type == 'text/html'
                    self.class.html_body_to_text(encoded_body)
                  else
                    self.class.plain_text_body_to_text(encoded_body)
                  end
      text_body.gsub!(/[\r\n]+/, '<br />') if text_body && formatting == 'HTML'
      text_body
    end.join((formatting == 'HTML') ? '<br />' : "\r\n")
  end

  def cleanup_body(body)
    cleanup_body = body.dup
    delimiters   = Setting.mail_handler_body_delimiters.to_s.split(/[\r\n]+/).reject(&:blank?)

    if Setting.mail_handler_enable_regex_delimiters?
      begin
        delimiters = delimiters.map { |s| Regexp.new(s) }
      rescue RegexpError => e
        logger.error "MailHandler: invalid regexp delimiter found in mail_handler_body_delimiters setting (#{e.message})" if logger
      end
    end

    unless delimiters.empty?
      regex        = Regexp.new("^[> ]*(#{ Regexp.union(delimiters) })[[:blank:]]*[\r\n].*", Regexp::MULTILINE)
      cleanup_body = body.gsub(regex, '')
    end
    cleanup_body = cleanup_body.strip
    return cleanup_body unless Setting.text_formatting == 'HTML'

    parse_body = Nokogiri::HTML.parse(cleanup_body)
    ['head', 'meta', 'style', 'script', 'base'].each do |trash|
      parse_body.search(trash).remove
    end
    # remove blank p, that create empty lines.
    parse_body.css('p').each { |p| p.remove if p.content.strip.blank? }

    body_html = parse_body.at('body')

    msg = '<div class="easy_long_note"><div>'
    msg << (body_html.present? ? body_html.inner_html : parse_body.text)
    msg << '</div></div>'

    return msg
  end

  protected

  def log_info_msg(err_msg)
    if handler_options[:logger]
      handler_options[:logger].info(err_msg)
    elsif logger
      logger.info(err_msg)
    end
    update_easy_rake_task_info_detail(err_msg)
  end

  def log_error_msg(err_msg)
    if handler_options[:logger]
      handler_options[:logger].error(err_msg)
    elsif logger
      logger.error(err_msg)
    end
    update_easy_rake_task_info_detail(err_msg)
  end

  def update_easy_rake_task_info_detail(err_msg)
    if handler_options[:easy_rake_task_info_detail]
      handler_options[:easy_rake_task_info_detail].update_column(:detail, err_msg)
    end
  end

  def mails_from_and_cc_hash(email)
    mails = { to: [], cc: [] }
    return mails if email.nil?

    mails[:to].concat(Array.wrap(email.reply_to)) if !email.reply_to.blank?
    mails[:to].concat(Array.wrap(email.from)) if !email.from.blank?
    mails[:cc] = all_mails_cc_array(email)

    mails[:to] = mails[:to].flatten.reject(&:blank?).map { |mail| mail.to_s.strip.downcase }.uniq
    mails[:cc] = mails[:cc].flatten.reject(&:blank?).map { |mail| mail.to_s.strip.downcase }.uniq
    mails
  end

  def mails_from_and_cc(email)
    mails      = mails_from_and_cc_hash(email)
    mails[:to] = mails[:to].join(', ')
    mails[:cc] = mails[:cc].join(', ')
    mails
  end

  def all_mails_cc_array(email, issue = nil)
    mails_cc = []

    if issue&.easy_email_cc.present?
      mails_cc.concat(issue.easy_email_cc.scan(EasyExtensions::Mailer::EMAIL_REGEXP))
    end

    if email && email.cc.present?
      cc = Array.wrap(email.cc).grep(EasyExtensions::Mailer::EMAIL_REGEXP)
      mails_cc.concat(cc)
    end

    if email && email.to.present?
      to = Array.wrap(email.to).grep(EasyExtensions::Mailer::EMAIL_REGEXP)
      mails_cc.concat(to)
    end

    if handler_options[:easy_helpdesk_mailbox_username].present?
      sender_mail = handler_options[:easy_helpdesk_mailbox_username].match(EasyExtensions::Mailer::EMAIL_REGEXP).to_s
      mails_cc.delete(sender_mail) if sender_mail.present?
    end

    emission_address = Setting.mail_from.to_s.gsub(/(?:.*<|>.*|\(.*\))/, '').strip
    if emission_address.present? && mails_cc.any? { |cc| cc.casecmp(emission_address) == 0 }
      mails_cc.delete(emission_address)
    end

    if issue&.easy_email_to.present?
      customer_mail = issue.easy_email_to.match(EasyExtensions::Mailer::EMAIL_REGEXP).to_s
      mails_cc.delete(customer_mail) if customer_mail.present?
    end

    mails_cc.uniq
  end

  def pick_encoding(part)
    Mail::RubyVer.respond_to?(:pick_encoding) ? Mail::RubyVer.pick_encoding(part.charset).to_s : part.charset
  end

  def convert_to_utf8(str, encoding)
    if !str.nil? && encoding.to_s.casecmp('utf-7').zero? && Net::IMAP.respond_to?(:decode_utf7)
      str.force_encoding('UTF-8')
      Redmine::CodesetUtil.to_utf8(Net::IMAP.decode_utf7(str), 'UTF-8')
    else
      Redmine::CodesetUtil.to_utf8(str, encoding)
    end
  end

end
