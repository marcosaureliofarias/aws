class EasySlaEvent < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :issue
  belongs_to :issue_status
  belongs_to :user

  scope :visible, lambda { |*args|
    where(EasySlaEvent.visible_condition(args.shift || User.current, *args)).joins(:project)
  }

  scope :sorted, lambda { order("#{table_name}.name ASC") }
  validates :project_id, :issue_id, presence: true

  safe_attributes \
    'name',
    'occurence_time',
    'issue_id',
    'user_id',
    'sla_response',
    'sla_resolve',
    'first_response',
    'sla_response_fulfilment',
    'sla_resolve_fulfilment',
    'project_id',
    'issue_status_id'

  def self.visible_condition(user, options={})
    return '1=1' if User.current.admin?
    Project.allowed_to_condition(user, :view_easy_sla_events, options)
  end


  def visible?(user = nil)
    user ||= User.current
    user.allowed_to?(:view_easy_sla_events, self.project)
  end

  def deletable?(user = nil)
    user ||= User.current
    user.allowed_to?(:manage_easy_sla_events, self.project)
  end

  def to_s
    name.to_s
  end

  def created_on
    created_at
  end

  def updated_on
    updated_at
  end

  def self.create_easy_sla_event(issue)
    sla_condition = issue.closed? || Array.wrap(EasySetting.value(:easy_helpdesk_sla_stop_states)).include?(issue.status_id.to_s) || EasySetting.value(:easy_helpdesk_ignorate_suspend_statuses)
    return unless issue.easy_helpdesk_project_sla_id && sla_condition
    name = "#{User.current.name} ##{issue.id}"
    occurence_time = Time.now.localtime

    sla_resolve = issue.easy_due_date_time
    sla_response = issue.easy_response_date_time

    first_response_time = ((Time.now.localtime - issue.created_on.localtime) / 1.hour) if !issue.easy_sla_events.any?

    response_time = (sla_response.localtime - (issue.easy_sla_events.present? ? issue.easy_sla_events.first.created_at.localtime : occurence_time)) / 1.hour

    resolve_time = issue.easy_helpdesk_project_sla_time_to_solve

    EasySlaEvent.create(
      name: name,
      occurence_time: occurence_time,
      issue_id: issue.id,
      issue_status_id: issue.status_id,
      project_id: issue.project_id,
      user_id: User.current.id,
      sla_response: sla_response,
      sla_resolve: sla_resolve,
      first_response: first_response_time,
      sla_response_fulfilment: response_time,
      sla_resolve_fulfilment: resolve_time
    )
  end

end
