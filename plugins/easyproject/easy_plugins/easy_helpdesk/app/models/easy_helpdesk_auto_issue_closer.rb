class EasyHelpdeskAutoIssueCloser < ActiveRecord::Base
  enum inactive_interval_unit: [:days, :hours]

  MODES = %i[notify change]
  serialize :auto_update_modes, Array

  validate :auto_update_modes_check

  belongs_to :easy_helpdesk_project
  belongs_to :observe_issue_status, :foreign_key => :observe_issue_status_id, :class_name => 'IssueStatus'
  belongs_to :done_issue_status, :foreign_key => :done_issue_status_id, :class_name => 'IssueStatus'
  belongs_to :done_issue_user, :foreign_key => :done_issue_user_id, :class_name => 'Principal'
  belongs_to :easy_helpdesk_mail_template

  def interval_for_close
    if inactive_interval.present? && inactive_interval > 0
      inactive_interval.send(inactive_interval_unit)
    else
      3.days
    end
  end

  def auto_update_modes
    super.map(&:to_sym)
  end

  def change_issue?
    @change_issue ||= auto_update_modes.include?(:change)
  end

  def notify_customer?
    @notify_customer ||= auto_update_modes.include?(:notify)
  end

  private

  def auto_update_modes_check
    if easy_helpdesk_project.automatically_issue_closer_enable? && (auto_update_modes.empty? || auto_update_modes.any?{|mode| !MODES.include?(mode)})
      errors.add(:auto_update_modes, :invalid)
    end
  end
end
