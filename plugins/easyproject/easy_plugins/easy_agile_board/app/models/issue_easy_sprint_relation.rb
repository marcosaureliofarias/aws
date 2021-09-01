require 'easy_agile_board/easy_agile_board'

class IssueEasySprintRelation < ActiveRecord::Base
  include Redmine::SafeAttributes

  include EasyAgileBoard::EasyAgileExtensions
  easy_agile_options(easy_setting_name: 'agile_board_statuses', phase_column: 'relation_type')

  TYPE_BACKLOG      = :backlog
  TYPE_PROGRESS     = :progress
  TYPE_DONE         = :done
  PROJECT_BACKLOG   = :project_backlog

  TYPES = ActiveSupport::OrderedHash[{
      TYPE_BACKLOG      => -1,
      TYPE_PROGRESS     => 1..2**31-1,
      TYPE_DONE         => -2
    }].freeze

  DEFAULT_TYPE = TYPES[TYPE_BACKLOG]

  belongs_to :issue
  belongs_to :easy_sprint

  delegate :project_id, :project, to: :easy_sprint

  acts_as_positioned scope: :relation_position

  before_save :ensure_new_position

  scope :until_only_for, ->(relation_types, until_date) { until_only_for_scope(relation_types, until_date).preload(:issue) }
  scope :between_only_for, ->(relation_types, start_date, end_date) { between_only_for_scope(relation_types, start_date, end_date).preload(:issue) }
  scope :with_relation, ->(relation_types) { where(relation_type: Array.wrap(relation_types).collect{|r| TYPES[r] }) }

  scope :visible, -> (*args) { where(issue_id: Issue.visible(*args)) }

  validates :issue, :relation_type, presence: true

  attr_accessor :new_position

  safe_attributes 'new_position'

  def self.column_for_rating(easy_sprint_id, project_id)
    easy_sprint_burndown = EasySetting.value("easy_sprint_burndown_#{easy_sprint_id}")
    return unless easy_sprint_burndown
    cache = RequestStore.store[:sprint_column_for_sum] ||= {}
    cache[easy_sprint_id] ||= EasyIssueQuery.new(project_id: project_id).get_column(easy_sprint_burndown)
  end

  def self.until_only_for_scope(relation_types = :all, until_date = nil)
    scope = all
    scope = scope.where(["#{IssueEasySprintRelation.table_name}.updated_at <= ?", until_date.end_of_day.to_datetime]) if until_date
    scope = scope.with_relation(relation_types) unless relation_types == :all
    scope
  end

  def self.between_only_for_scope(relation_types = :all, start_date = nil, end_date = nil)
    scope = all
    scope = scope.where(["#{IssueEasySprintRelation.table_name}.updated_at >= ?", start_date.beginning_of_day.to_datetime]) if start_date
    scope = scope.where(["#{IssueEasySprintRelation.table_name}.updated_at <= ?", end_date.end_of_day.to_datetime]) if end_date
    scope = scope.where(relation_type: relation_types.collect { |r| IssueEasySprintRelation::TYPES[r] }) unless relation_types == :all
    scope
  end

  def self.kanban_phase_for_statuses(issue, project, use_workflow = false)
    return [] unless User.current.allowed_to?(:edit_easy_scrum_board, project)
    kanban_statuses = EasySetting.value('agile_board_statuses', project) || {}
    kanban_statuses = kanban_statuses.to_unsafe_hash if kanban_statuses.respond_to?(:to_unsafe_hash)
    kanban_statuses = kanban_statuses.symbolize_keys
    return TYPES.values.map(&:to_s).concat(kanban_statuses[:progress].try(:keys) || []) unless use_workflow
    status_ids = issue.new_statuses_allowed_to(User.current).map(&:id)
    possible_phases = [TYPES[TYPE_BACKLOG].to_s]
    if !kanban_statuses[:done] || kanban_statuses[:done]['status_id'].blank? || status_ids.include?(kanban_statuses[:done]['status_id'].to_i)
      possible_phases << TYPES[TYPE_DONE].to_s
    end
    kanban_statuses[:progress] && kanban_statuses[:progress].each do |k,v|
      possible_phases << k if v['status_id'].blank? || status_ids.include?(v['status_id'].to_i)
    end
    possible_phases
  end

  def easy_agile_rating(options = {})
    rating_mode_column = self.class.column_for_rating(easy_sprint_id, project_id)
    return 0.0 unless rating_mode_column
    rating_mode_column.value(issue).to_f
  end

  private

  def ensure_new_position
    return if self.new_position.blank?
    new_new_position = self.new_position
    self.new_position = nil
    if new_new_position != :bottom
      self.position = new_new_position.to_i
    end
  end

  def position_scope
    cond = easy_sprint_id.present? ? "easy_sprint_id = '#{easy_sprint_id}'" : "easy_sprint_id IS NULL"
    cond << " AND relation_type = '#{relation_type}'" if relation_type.present?
    cond << " AND relation_position = '#{relation_position}'" if relation_position.present?
    self.class.where(cond)
  end

  def position_scope_was
    method = destroyed? ? '_was' : '_before_last_save'
    easy_sprint_id_prev = send('easy_sprint_id' + method)
    relation_type_prev = send('relation_type' + method)
    relation_position_prev = send('relation_position' + method)
    cond = easy_sprint_id_prev.present? ? "easy_sprint_id = '#{easy_sprint_id_prev}'" : "easy_sprint_id IS NULL"
    cond << " AND relation_type = '#{relation_type_prev}'" if relation_type_prev.present?
    cond << " AND relation_position = '#{relation_position_prev}'" if relation_position_prev.present?
    self.class.where(cond)
  end

end
