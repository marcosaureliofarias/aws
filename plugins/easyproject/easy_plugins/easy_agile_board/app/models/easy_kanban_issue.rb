require 'easy_agile_board/easy_agile_extensions'

class EasyKanbanIssue < ActiveRecord::Base
  include Redmine::SafeAttributes

  include EasyAgileBoard::EasyAgileExtensions
  easy_agile_options(easy_setting_name: 'kanban_statuses', phase_column: 'phase', easy_sprint_method: nil)

  TYPE_NOT_ASSIGNED = :null
  TYPE_BACKLOG      = :backlog
  TYPE_PROGRESS     = :progress
  TYPE_DONE         = :done

  TYPES = ActiveSupport::OrderedHash[{
      TYPE_NOT_ASSIGNED => 0,
      TYPE_BACKLOG      => -1,
      TYPE_PROGRESS     => 1,
      TYPE_DONE         => -2
    }].freeze

  belongs_to :project
  belongs_to :issue

  scope :of_project, ->(project) { where(project_id: project.id) }

  acts_as_positioned scope: :phase

  safe_attributes 'phase'

  def self.not_assigned_phase?(phase)
    phase.to_i == TYPES[TYPE_NOT_ASSIGNED]
  end

  def self.kanban_phase_for_statuses(issue, project, use_workflow = false)
    return [] unless User.current.allowed_to?(:edit_easy_kanban_board, project)
    kanban_statuses = EasySetting.value('kanban_statuses', project) || {}
    kanban_statuses = kanban_statuses.to_unsafe_hash if kanban_statuses.respond_to?(:to_unsafe_hash)
    kanban_statuses = kanban_statuses.symbolize_keys
    return TYPES.except(TYPE_NOT_ASSIGNED).values.map(&:to_s).concat(kanban_statuses[:progress].try(:keys) || []) unless use_workflow
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

  def phase=(type)
    type = TYPES[type] if type.is_a?(Symbol)
    super(type)
  end

  def phase_type
    if TYPES.invert.key?(phase)
      TYPES.invert[phase]
    else
      TYPE_PROGRESS
    end
  end

end
