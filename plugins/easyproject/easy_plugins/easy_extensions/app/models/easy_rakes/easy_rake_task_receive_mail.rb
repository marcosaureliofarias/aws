require 'easy_extensions/imap'
require 'easy_extensions/pop3'

class EasyRakeTaskReceiveMail < EasyRakeTask

  # == IMAP:
  # folder::
  #   are saved as 'Folder1\r\nFolder2\r\nFolder3'
  #   (advantage: for textarea form)
  #   (disadvantage: must be parsed for imap.select)

  after_initialize :set_default_settings, :if => Proc.new { |e| e.new_record? }
  before_create :set_default_values

  validate :validate_unique_mailbox

  def settings_view_path
    'easy_rake_tasks/settings/easy_rake_task_receive_mail'
  end

  def info_detail_status_caption(status)
    EasyRakeTaskInfoDetailReceiveMail.status_caption(status)
  end

  def caption
    s = super
    s << " (#{self.username_caption})" unless self.username_caption.blank?
    s
  end

  def username_caption
    # ActiveSupport::Deprecation.warn "#username_caption is deprecated, use just #username because mailbox may now have more folders"

    return @username_caption if @username_caption
    @username_caption = ''

    if !self.username.blank? || !self.folder_name.blank?
      @username_caption << self.username unless self.username.blank?
      @username_caption << "/#{self.folder_name}" unless self.folder_name.blank?
    end

    @username_caption
  end

  def settings_by_connection_type
    if self.settings['connection_type'] == 'pop3'
      self.settings['pop3']
    elsif self.settings['connection_type'] == 'imap'
      self.settings['imap']
    else
      Hash.new
    end
  end

  def host
    self.settings_by_connection_type['host']
  end

  def username
    self.settings_by_connection_type['username']
  end

  def sender_mail
    sender = self.settings_by_connection_type['sender_mail'] if self.settings_by_connection_type['use_custom_sender'] == 'true'
    sender = self.username if sender.blank?
    sender
  end

  def folder_name
    self.settings_by_connection_type['folder'].to_s.split.join(', ')
  end

  def execute
    Timeout.timeout(30.minutes) do
      if self.settings['connection_type'] == 'pop3'
        self.execute_pop3
      elsif self.settings['connection_type'] == 'imap'
        self.execute_imap
      end
    end
  rescue Timeout::Error
    [false, l(:text_easy_helpdesk_mailbox_too_long_to_process)]
  end

  def imap_options
    result = {}
    %w(host port ssl username password folder move_on_success move_on_failure dont_verify_server_cert).each do |key|
      value = self.settings['imap'][key]
      unless value.blank?
        result[key.to_sym] = value
      end
    end
    result
  end

  def execute_pop3
    set_default_settings
    pop_options = {}

    %w(host port apop ssl username password delete_unprocessed dont_verify_server_cert).each do |key|
      pop_options[key.to_sym] = self.settings['pop3'][key.to_s] unless self.settings['pop3'][key.to_s].blank?
    end

    options                                  = self.create_default_options_from_settings(self.settings['pop3'])
    options[:easy_helpdesk_mailbox_username] = self.sender_mail
    options[:no_issue_validation]            = true
    options[:easy_rake_task]                 = self

    return EasyExtensions::POP3.check(pop_options, options)
  end

  def execute_imap
    set_default_settings
    options                                  = self.create_default_options_from_settings(self.settings['imap'])
    options[:easy_helpdesk_mailbox_username] = self.sender_mail
    options[:no_issue_validation]            = true
    options[:easy_rake_task]                 = self

    Mailer.with_synched_deliveries do
      EasyExtensions::IMAP.check(imap_options, options)
    end
  end

  def imap_folders
    set_default_settings
    options = self.create_default_options_from_settings(self.settings['imap'])
    EasyExtensions::IMAP.available_folders(imap_options, options)
  end

  def test_connection
    set_default_settings
    if self.settings['connection_type'] == 'pop3'
      self.test_connection_pop3
    elsif self.settings['connection_type'] == 'imap'
      self.test_connection_imap
    end
  end

  def test_connection_pop3
    pop_options = {}

    %w(host port apop ssl username password delete_unprocessed dont_verify_server_cert).each do |key|
      pop_options[key.to_sym] = self.settings['pop3'][key.to_s] unless self.settings['pop3'][key.to_s].blank?
    end
    EasyExtensions::POP3.test_connection(pop_options)
  end

  def test_connection_imap
    EasyExtensions::IMAP.test_connection(imap_options)
  end

  def create_default_options_from_settings(s)
    options = {}

    options[:unknown_user] = s['unknown_user'] || 'accept'

    if s.key?('no_permission_check')
      options[:no_permission_check] = s['no_permission_check']
    else
      options[:no_permission_check] = '1'
    end

    options
  end

  def set_default_values
    self.period      = :minutes
    self.interval    = 5
    self.next_run_at = Time.now
  end

  def set_default_settings
    self.settings                    ||= {}
    self.settings['pop3']            ||= {}
    self.settings['imap']            ||= {}
    self.settings['connection_type'] ||= 'imap'
  end

  def validate_unique_mailbox
    scope = self.class.select(:id, :settings).active
    unless new_record?
      scope = scope.where.not(:id => self.id)
    end

    same_mailboxes = scope.to_a.select do |other_mailbox|
      self.same_mailbox?(other_mailbox)
    end

    return if same_mailboxes.empty?

    link = mailbox_link(same_mailboxes.first)
    errors.add(:base, I18n.t(:error_mailbox_already_exists, link: link).html_safe)
  end

  def same_mailbox?(other)
    ['host', 'username'].each do |attribute|
      if self.settings_by_connection_type[attribute] == other.settings_by_connection_type[attribute]
        # equal parameters
        # true at the end
      else
        return false
      end
    end

    true
  end

  def mailbox_link(mailbox)
    path = Rails.application.routes.url_helpers.url_for(
        controller: 'easy_rake_tasks', action: 'edit', id: mailbox,
        only_path:  true
    )

    "<a href='#{path}'>#{mailbox.caption}</a>"
  end

end
