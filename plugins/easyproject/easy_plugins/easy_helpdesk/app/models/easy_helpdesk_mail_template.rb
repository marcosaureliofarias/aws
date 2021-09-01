class EasyHelpdeskMailTemplate < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :issue_status
  has_and_belongs_to_many :mailboxes,
                          class_name:              'EasyRakeTaskEasyHelpdeskReceiveMail',
                          join_table:              'easy_helpdesk_mail_templates_mailboxes',
                          foreign_key:             'mail_template_id',
                          association_foreign_key: 'mailbox_id'

  validates :subject, :name, presence: true
  validate :validate_mailboxes

  attr_accessor :send_to, :send_cc

  before_save :ensure_default_template, if: -> { is_default? }

  safe_attributes 'mailbox_ids', 'subject', 'body_html', 'body_plain', 'issue_status_id', 'name', 'is_default'

  def self.find_from_issue(issue)
    scope = EasyHelpdeskMailTemplate.joins(:mailboxes)
    if issue.easy_helpdesk_mailbox_username.present?
      mx = EasyRakeTaskEasyHelpdeskReceiveMail.all.detect { |m| m.sender_mail.to_s.strip == issue.easy_helpdesk_mailbox_username.to_s.strip }
      scope = scope.where(["#{EasyRakeTaskEasyHelpdeskReceiveMail.table_name}.id = ?", mx.id]) if mx
    end
    scope.find_by(issue_status_id: issue.status_id)
  end

  def self.find_all_for_issue(issue)
    return [] unless issue.is_a?(Issue)

    if issue.easy_helpdesk_mailbox_username.blank?
      EasyHelpdeskMailTemplate.order(:name)
    else
      find_all_for_mailbox_username(issue.easy_helpdesk_mailbox_username)
    end
  end

  def self.find_all_for_mailbox_username(mailbox_username)
    return [] if mailbox_username.blank?

    EasyHelpdeskMailTemplate.order(:name).preload(:mailboxes).to_a.select do |t|
      m = t.mailboxes.first
      if m
        m.sender_mail.to_s.strip == mailbox_username.to_s.strip
      else
        false
      end
    end
  end

  def self.default
    EasyHelpdeskMailTemplate.where(is_default: true).take
  end

  def caption
    return @caption if @caption

    @caption = ''
    @caption << "(#{self.mailboxes.first.username_caption}) - " if self.mailboxes.first
    @caption << self.subject

    @caption
  end

  private

  def validate_mailboxes
    errors.add(:mailboxes, :blank) if self.mailboxes.blank?
  end

  def ensure_default_template
    EasyHelpdeskMailTemplate.where(is_default: true).where.not(id: id).update_all(is_default: false)
  end

end
