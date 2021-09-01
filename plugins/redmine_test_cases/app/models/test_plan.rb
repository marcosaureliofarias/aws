class TestPlan < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'

  has_many :entity_assignments, class_name: 'EasyEntityAssignment', as: :entity_from
  has_many :test_cases, through: :entity_assignments, source: :entity_to, source_type: 'TestCase', validate: false
  has_many :issues, through: :entity_assignments, source: :entity_to, source_type: 'Issue', validate: false

  acts_as_customizable

  validates :project_id, :author_id, :name, presence: true
  validates :name, length: { maximum: 255 }

  safe_attributes 'name', 'author_id'
  safe_attributes 'custom_field_values', 'custom_fields'
  safe_attributes 'project_id', if: lambda { |test_case, _user| test_case.new_record? }
  safe_attributes 'test_case_ids'

  scope :like, ->(term) { where("LOWER(#{TestPlan.table_name}.name) LIKE :term OR CAST(#{TestPlan.table_name}.id AS CHAR(16)) LIKE :term", { term: "%#{term.to_s.downcase}%" }) }

  scope :visible, lambda { |*args|
    where(TestPlan.visible_condition(args.shift || User.current, *args)).joins(:project)
  }

  def self.visible_condition(user, options={})
    Project.allowed_to_condition(user, :view_test_plans, options)
  end

  def visible?(user = User.current)
    user.allowed_to?(:view_test_plans, self.project, global: true)
  end

  def editable?(user = User.current)
    user.allowed_to?(:manage_test_plans, self.project, global: true)
  end

  def deletable?(user = User.current)
    user.allowed_to?(:manage_test_plans, self.project, global: true)
  end

  def copy_from(test_plan, options={})
    self.author_id = test_plan.author_id
    self.name = test_plan.name
    self.created_at = test_plan.created_at
    self.updated_at = test_plan.updated_at
    self.custom_field_values = test_plan.custom_field_values.inject({}) { |h, v| h[v.custom_field_id] = v.value_for_params; h }
  end

  def to_s
    self.name
  end
end