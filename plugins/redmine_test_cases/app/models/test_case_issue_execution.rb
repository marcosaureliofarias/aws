class TestCaseIssueExecution < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  belongs_to :test_case
  belongs_to :issue
  belongs_to :test_case_issue_execution_result, foreign_key: 'result_id'
  has_one :project, through: :issue
  has_many :test_plans, through: :test_case

  if Redmine::Plugin.installed? :easy_agile_board
    has_one :easy_sprint, through: :issue
  end

  scope :visible, lambda { |*args|
    where(TestCaseIssueExecution.visible_condition(args.shift || User.current, *args))
  }

  include EasyExtensions::EasyInlineFragmentStripper
  strip_inline_images :comments

  acts_as_customizable
  acts_as_attachable

  validates :author_id, :test_case_id, :issue_id, :presence => true


  safe_attributes 'test_case', 'author_id', 'issue_id', 'result_id'
  safe_attributes 'custom_field_values', 'custom_fields', 'comments'

  after_create_commit :send_create_notification
  after_update_commit :send_update_notification

  delegate :tracker, to: :issue

  enum result: [:pass, :fail]

  def self.human_attribute_name(attribute, *args)
    l(attribute.to_s.gsub(/\_id$/, ''), :scope => [:activerecord, :attributes, :test_case_issue_execution])
  end

  def self.visible_condition(user, options={})
    '1=1'
  end

  def self.css_icon
    'icon icon-user'
  end

  def to_s
    [test_case.try(:name), test_case_issue_execution_result.try(:name)].compact.join(' - ')
  end

  def visible?(user = nil)
    user ||= User.current
    user.allowed_to?(:view_test_case_issue_executions, self.project, global: true)
  end

  def editable?(user = nil)
    user ||= User.current
    user.allowed_to?(:manage_test_case_issue_executions, self.project, global: true)
  end

  def deletable?(user = nil)
    user ||= User.current
    user.allowed_to?(:manage_test_case_issue_executions, self.project, global: true)
  end

  def attachments_visible?(user = nil)
    visible?(user)
  end

  def attachments_editable?(user = nil)
    editable?(user)
  end

  def attachments_deletable?(user = nil)
    deletable?(user)
  end

  def created_on
    created_at
  end

  def updated_on
    updated_at
  end

  def notified_users
    if project
      project.notified_users.reject { |user| !visible?(user) }
    else
      [User.current]
    end
  end

  def send_create_notification
    # if Setting.notified_events.include?('test_case_issue_execution_added')
    TestCaseIssueExecutionMailer.deliver_test_case_issue_execution_added(self)
    # end
  end

  def send_update_notification
    # if Setting.notified_events.include?('test_case_issue_execution_updated')
    TestCaseIssueExecutionMailer.deliver_test_case_issue_execution_updated(self)
    # end
  end

  def copy_from(issue_execution, options={})
    issues_map = options[:issues_map] || {}

    issue = issues_map[issue_execution.issue_id]
    self.issue_id = issue.id if issue
    self.result = issue_execution.result
    self.result_id = issue_execution.result_id
    self.author_id = issue_execution.author_id
    self.comments = issue_execution.comments
    self.created_at = issue_execution.created_at
    self.updated_at = issue_execution.updated_at
    self.custom_field_values = issue_execution.custom_field_values.inject({}) { |h, v| h[v.custom_field_id] = v.value_for_params; h }
  end

end
