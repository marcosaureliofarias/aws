module EasyAgileBoard
  module IssuePatch

    def self.included(base)

      base.class_eval do

        belongs_to :easy_sprint
        has_many :easy_kanban_issues, dependent: :destroy
        has_one :issue_easy_sprint_relation, dependent: :destroy
        has_one :easy_agile_backlog_relation, dependent: :destroy

        scope :with_kanban_issues_of_project, ->(project) { joins(:easy_kanban_issues).where('easy_kanban_issues.project_id = ?', project.id) }


        after_create :add_issue_to_backlog, if: -> { project && self.target_backlog && !EasySetting.value('add_new_issues_to_project_kanban', project) }
        before_save :update_associated_easy_agile_backlog_relation
        after_save :create_or_update_agile_associations
        after_commit :autocreate_easy_kanban_issue, on: :create, if: -> { EasySetting.value('add_new_issues_to_project_kanban', project) }

        validates :easy_story_points, numericality: { only_integer: true, allow_nil: true }

        attr_accessor :skip_update_associated_agile_relations, :easy_kanban_issue, :target_backlog

        # TODO: Add permissions
        safe_attributes 'easy_sprint_id', 'easy_story_points', 'target_backlog', 'easy_project_backlog'

        journalized_options[:format_detail_reflection_columns] << 'easy_sprint_id'

        ##### AGILE 2016

        def easy_kanban_issue(project)
          @easy_kanban_issue ||= self.easy_kanban_issues.of_project(project).first
        end

        def kanban_phase(project)
          self.easy_kanban_issue(project) && self.easy_kanban_issue(project).phase
        end

        def scrum_phase
          self.issue_easy_sprint_relation && self.issue_easy_sprint_relation.relation_type
        end

        def easy_agile_rating(options = {})
          issue_easy_sprint_relation.easy_agile_rating(options)
        end

        def update_associated_easy_agile_backlog_relation
          self.easy_agile_backlog_relation = nil if closing? && easy_agile_backlog_relation
        end

        def create_or_update_agile_associations
          return true if skip_update_associated_agile_relations

          if self.easy_kanban_issues.any?
            self.easy_kanban_issues.each(&:update_from_issue)
          end

          if !self.easy_sprint_id || !self.easy_sprint
            self.issue_easy_sprint_relation.destroy if self.issue_easy_sprint_relation
            return true
          end

          self.build_issue_easy_sprint_relation unless self.issue_easy_sprint_relation
          self.issue_easy_sprint_relation.easy_sprint_id = self.easy_sprint_id
          self.issue_easy_sprint_relation.update_from_issue

          true
        end

        def autocreate_easy_kanban_issue
          self.skip_update_associated_agile_relations = true
          eki = EasyKanbanIssue.create(issue: self, project: project, phase: EasyKanbanIssue::TYPES[EasyKanbanIssue::TYPE_BACKLOG])
          eki.update_from_issue
        end

        def add_issue_to_backlog
          if self.target_backlog == 'project_backlog'
            EasyAgileBacklogRelation.create(issue: self, project: project)
          elsif self.target_backlog == 'sprint_backlog'
            self.skip_update_associated_agile_relations = true
            IssueEasySprintRelation.create(issue: self, easy_sprint: easy_sprint, relation_type: IssueEasySprintRelation::TYPES[IssueEasySprintRelation::TYPE_BACKLOG])
          end
        end

        def easy_project_backlog=(backlog_project)
          if closed?
            errors.add(:base, I18n.t(:error_assign_closed_issues_to_project_backlog))
            return nil
          end

          if !backlog_project.is_a?(Project)
            backlog_project = Project.find_by(id: backlog_project)
          end

          if backlog_project
            if id
              IssueEasySprintRelation.where(issue_id: id).destroy_all
              update(easy_sprint: nil) if easy_sprint
            end

            if assignment = easy_agile_backlog_relation
              assignment.project = backlog_project
            else
              assignment = backlog_project.easy_agile_backlog_relations.build(issue: self)
            end

            assignment.save
          end
        end

      end
    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Issue', 'EasyAgileBoard::IssuePatch'
