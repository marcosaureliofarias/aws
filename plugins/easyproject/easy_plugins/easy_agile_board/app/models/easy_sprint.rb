class EasySprint < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :version
  has_many :issue_easy_sprint_relations, dependent: :destroy
  has_many :issues, dependent: :nullify

  validates :name, :start_date, :project, presence: true
  validates :due_date, allow_nil: true, presence: true
  validates :display_closed_tasks_in_last_n_days, allow_nil: true, numericality: { greater_than: 0 }
  validates :capacity, allow_nil: false, numericality: { greater_than_or_equal_to: 0 }
  validate :validate_version_and_due_date

  html_fragment :goal, scrub: :strip

  scope :opened, -> { where(closed: false) }
  scope :actual, -> { opened.where(["#{EasySprint.quoted_table_name}.due_date >= ? OR #{EasySprint.quoted_table_name}.due_date IS NULL", Date.today]) }
  scope :without_due_date, -> { where.not(due_date: nil) }
  # scope :future, -> {where(["#{EasySprint.quoted_table_name}.start_date > ?", Date.today])}
  # scope :past, -> {where(["#{EasySprint.quoted_table_name}.due_date < ?", Date.today])}

  # id keeps order defined by next and previous method
  scope :sorted_by_date, -> { order("#{EasySprint.table_name}.start_date DESC, #{EasySprint.table_name}.id DESC") }

  scope :sorted_by_project, -> { includes(:project).order("#{Project.table_name}.name ASC") }

  scope :of_project_with_global, ->(project) {
    if project.presence
      opened.where(EasySprint.arel_table[:cross_project].eq(true).or(EasySprint.arel_table[:project_id].in(project.self_and_ancestors.pluck(:id))))
    end
  }

  scope :like, lambda {|arg|
    if arg.blank?
      where(nil)
    else
      pattern = "%#{arg.to_s.strip.downcase}%"
      where(Redmine::Database.like('name', ':p'), p: pattern)
    end
  }

  scope :visible, -> (*args) { where(project_id: Project.where(Project.allowed_to_condition(args.shift || User.current, :view_easy_scrum_board, *args))) }

  after_initialize :set_defaults
  after_destroy :delete_easy_setting

  safe_attributes 'name', 'goal', 'start_date', 'due_date', 'capacity', 'version_id', 'cross_project', 'display_closed_tasks_in_last_n_days'

  def assign_issue(issue, relation_type, relation_position, assigned_to_id, update_issue = true, row_position = nil)
    return errors.add(:base, l(:error_assign_issue_to_closed_easy_sprint)) if self.closed?

    relation_position = nil if relation_position.blank?

    assignment = issue.issue_easy_sprint_relation
    assignment ||= issue.build_issue_easy_sprint_relation

    EasyAgileBacklogRelation.where(issue_id: issue.id).destroy_all

    assignment.easy_sprint_id = self.id
    assignment.relation_type = relation_type
    assignment.relation_position = relation_position
    assignment.new_position = row_position || :bottom
    assignment.update_issue(assigned_to_id: assigned_to_id) if update_issue
    assignment.save
  end

  def statuses_setting
    (EasySetting.value('agile_board_statuses', self.project_id) || {}).symbolize_keys
  end

  def positions_for_type(type)
    !statuses_setting[type].is_a?(Hash) || statuses_setting[type].has_key?('status_id') ? nil : statuses_setting[type].keys.map(&:to_i)
  end

  def status_setting(type, position)
    if position.nil?
      statuses_setting[type]
    else
      statuses_setting[type][position.to_s]
    end
  end

  def sum_easy_agile_rating(relation_types = :all, until_date = nil)
    rating_sum = issue_easy_sprint_relations.visible.until_only_for(relation_types, until_date).to_a.sum do |r|
      rating = sum_easy_agile_rating_cache(r)
      rating ||= 0.0

      rating > 0 ? rating : 0.0
    end

    rating_sum.round(3)
  end

  def sum_issues_attribute(attribute, relation_types = :all, until_date = nil)
    issue_easy_sprint_relations.visible.until_only_for(relation_types, until_date).to_a.sum do |r|
      rating = sum_issues_attribute_cache(attribute, r)
      rating ||= 0.0

      rating >= 0 ? rating : 0.0
    end
  end

  def sum_issues_spent_time(relation_types = :all, until_date = nil)
    sum_issues_attribute('spent_hours', relation_types, until_date )
  end

  def sum_issue_scope(only_closed = nil)
    scope = issues
    scope = scope.includes(:status).where(issue_statuses: { is_closed: only_closed }) if only_closed.present?
    scope
  end

  def sum_estimated_time(only_closed = nil)
    sum_issue_scope(only_closed).sum(:estimated_hours)
  end

  def sum_story_points(only_closed = nil)
    sum_issue_scope(only_closed).sum(:easy_story_points)
  end

  def next_easy_sprint
    scope = project.easy_sprints

    scope = yield scope if block_given?

    scope.where(["(#{EasySprint.table_name}.start_date > ? OR (#{EasySprint.table_name}.start_date = ? AND #{EasySprint.table_name}.id > ?)) AND #{EasySprint.table_name}.id <> ?", self.start_date, self.start_date, self.id, self.id]).order("#{EasySprint.table_name}.start_date ASC, #{EasySprint.table_name}.id ASC").first
  end

  def previous_easy_sprint
    scope = project.easy_sprints

    scope = yield scope if block_given?

    scope.where(["(#{EasySprint.table_name}.start_date < ? OR (#{EasySprint.table_name}.start_date = ? AND #{EasySprint.table_name}.id < ?)) AND #{EasySprint.table_name}.id <> ?", self.start_date, self.start_date, self.id, self.id]).order("#{EasySprint.table_name}.start_date DESC, #{EasySprint.table_name}.id DESC").first
  end

  def close_all_issues(close_status)
    issues.open.find_each(batch_size: 100) do |issue|
      issue.init_journal(User.current)
      issue.update_attribute(:status, close_status)
    end
  end

  def current_time_for_display_closed_tasks_in_last_n_days
    current_time_from_proper_timezone
  end

  def open?
    !closed?
  end

  def available_close_issue_statuses
    issues.map do |issue|
      issue.new_statuses_allowed_to(User.current, false).select{|s| s.is_closed? }
    end.reduce(:&) || []
  end

  def to_s
    self.name.to_s
  end

  def to_s_with_project
    self.project ? "#{self.project} - #{self.name}" : self.name
  end

  def capacity_attribute
    EasySetting.value("easy_sprint_burndown_#{id}")
  end

  private

  def sum_easy_agile_rating_cache(relation)
    @sum_easy_agile_rating_cache ||= {}
    @sum_easy_agile_rating_cache[relation.issue_id] ||= relation.easy_agile_rating(only_for_sum: true).to_f
  end

  def sum_issues_attribute_cache(attribute, relation)
    @sum_issues_cache ||= {}
    @sum_issues_cache[attribute] ||= {}
    @sum_issues_cache[attribute][relation.issue_id] ||= relation.issue.send(attribute) if relation.issue
  end

  def set_defaults
    if new_record?
      self.start_date = Date.today
      self.due_date = Date.today + 1.week
    end
  end

  def validate_version_and_due_date
    if self.version && !self.version.effective_date.nil? && !self.due_date.nil? && self.due_date > self.version.effective_date
      errors.add(:base, l(:error_effective_date_must_be_lower_than_due_date,
          effective_date: format_date(self.version.effective_date),
          due_date: format_date(self.due_date)))
    end

    if self.due_date && !(self.due_date >= self.start_date)
      errors.add(:base, l(:error_start_date_must_be_lower_than_due_date,
        start_date: format_date(self.start_date),
        due_date: format_date(self.due_date)))
    end
  end

  def delete_easy_setting
    EasySetting.where(name: "easy_sprint_burndown_#{self.id}").destroy_all
  end

end
