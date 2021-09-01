module EasyAgileBoard
  module ProjectPatch

    def self.included(base)

      base.class_eval do

        has_many :easy_sprints, dependent: :destroy
        has_many :easy_kanban_issues, dependent: :destroy
        has_many :issue_easy_sprint_relations, through: :easy_sprints
        has_many :easy_agile_backlog_relations, dependent: :destroy
        has_many :easy_agile_backlog_issues, -> { order("#{EasyAgileBacklogRelation.table_name}.position") }, through: :easy_agile_backlog_relations, source: :issue

        def current_easy_sprint
          scope = self.easy_sprints.preload(issues: [:assigned_to, :status, :priority, :project, :tracker]).sorted_by_date
          @current_easy_sprint = scope.actual.where(["#{EasySprint.quoted_table_name}.start_date <= ? OR #{EasySprint.quoted_table_name}.start_date IS NULL", Time.zone.today]).first
          @current_easy_sprint ||= scope.actual.first
          @current_easy_sprint ||= scope.first
        end

      end
    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Project', 'EasyAgileBoard::ProjectPatch'
