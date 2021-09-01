class TestCase < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'

  has_many :entity_assignments, class_name: 'EasyEntityAssignment', as: :entity_to, dependent: :delete_all
  has_many :issues, through: :entity_assignments, source: :entity_from, source_type: 'Issue', validate: false
  has_many :test_plans, through: :entity_assignments, source: :entity_from, source_type: 'TestPlan', validate: false

  has_many :test_case_issue_executions, dependent: :destroy

  scope :visible, lambda { |*args|
    where(TestCase.visible_condition(args.shift || User.current, *args)).joins(:project)
  }

  scope :sorted, lambda { order("#{table_name}.name ASC") }

  scope :like, ->(term) { where("LOWER(#{TestCase.table_name}.name) LIKE :term OR CAST(#{TestCase.table_name}.id AS CHAR(16)) LIKE :term", { term: "%#{term.to_s.downcase}%" }) }

  acts_as_searchable columns: ["#{TestCase.table_name}.name"],
                     date_column: :created_at
  acts_as_customizable
  acts_as_attachable
  acts_as_event title: :name,
                url: proc { |o| {controller: 'test_cases', action: 'show', id: o.id, project_id: o.project_id} },
                description: :scenario

  acts_as_activity_provider author_key: :author_id, timestamp: "#{table_name}.created_at"

  validates :project_id, :author_id, :name, presence: true
  validates :name, length: { maximum: 255 }
  validates :expected_result, length: { maximum: 60.kilobytes }, allow_nil: true


  safe_attributes 'name', 'scenario', 'author_id'
  safe_attributes 'custom_field_values', 'custom_fields'
  safe_attributes 'project_id', if: lambda { |test_case, _user| test_case.new_record? }
  safe_attributes 'issue_ids', 'test_plan_ids'

  after_create_commit :send_create_notification
  after_update_commit :send_update_notification

  def self.human_attribute_name(attribute, *args)
    l(attribute.to_s.gsub(/\_id$/, ''), :scope => [:activerecord, :attributes, :test_case])
  end

  def self.visible_condition(user, options={})
    Project.allowed_to_condition(user, :view_test_cases, options)
  end

  def self.css_icon
    'icon icon-user'
  end

  def visible?(user = nil)
    user ||= User.current
    user.allowed_to?(:view_test_cases, self.project, global: true)
  end

  def editable?(user = nil)
    user ||= User.current
    user.allowed_to?(:manage_test_cases, self.project, global: true)
  end

  def deletable?(user = nil)
    user ||= User.current
    user.allowed_to?(:manage_test_cases, self.project, global: true)
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

  def to_s
    name.to_s
  end

  def created_on
    created_at
  end

  def updated_on
    updated_at
  end

  def notified_users
    if project
      project.notified_users.reject {|user| !visible?(user)}
    else
      [User.current]
    end
  end

  def send_create_notification
    # if Setting.notified_events.include?('test_case_added')
    TestCaseMailer.deliver_test_case_added(self)
    # end
  end

  def send_update_notification
    # if Setting.notified_events.include?('test_case_updated')
    TestCaseMailer.deliver_test_case_updated(self)
    # end
  end

  def last_result
    test_case_issue_executions.order(updated_at: :desc).first.try(:result_id)
  end

  def copy_from(test_case, options={})
    self.author_id = test_case.author_id
    self.name = test_case.name
    self.scenario = test_case.scenario
    self.expected_result = test_case.expected_result
    self.created_at = test_case.created_at
    self.updated_at = test_case.updated_at
    self.custom_field_values = test_case.custom_field_values.inject({}) { |h, v| h[v.custom_field_id] = v.value_for_params; h }
  end

  def copy_test_case_issue_executions(test_case, options={})
    test_case.test_case_issue_executions.each do |issue_execution|
      new_issue_execution = TestCaseIssueExecution.new
      new_issue_execution.copy_from(issue_execution, options)
      new_issue_execution.test_case = self
      new_issue_execution.save(validate: false)

      issue_execution.attachments.each do |at|
        at_copy = at.copy
        at_copy.container_id = new_issue_execution.id
        at_copy.save(validate: false)
      end
    end
  end

  def expected_result_cf
    visible_custom_field_values.select { |cfv| cfv.custom_field.internal_name == 'test_case_expected_result' }.first
  end

  def expected_result_cfv
    custom_value = expected_result_cf
    return '' unless custom_value.present?
    custom_value.value
  end

  def expected_result_enabled?
    custom_field = available_custom_fields.detect { |cf| cf.internal_name == 'test_case_expected_result' }
    return false unless custom_field.present?
    !custom_field.disabled?
  end

  def self.expected_result_custom_field_id
    custom_field = CustomField.where(internal_name: 'test_case_expected_result').first
    return nil unless custom_field.present?
    custom_field.id
  end

end
