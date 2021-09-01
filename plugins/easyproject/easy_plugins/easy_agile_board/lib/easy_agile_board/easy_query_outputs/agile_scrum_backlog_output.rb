module EasyAgileBoard
  module EasyQueryOutputs
    class AgileScrumBacklogOutput < AgileScrumOutput

      def self.key
        'scrum_backlog'
      end

      def issues_for_backlog_query
        return @issues_for_backlog_query if @issues_for_backlog_query

        @issues_for_backlog_query = query.model.dup
        @issues_for_backlog_query.filters = @filters_was.except('easy_sprint_id')
        @issues_for_backlog_query.entity_scope = @scope_was.includes(
          :issue_easy_sprint_relation, :easy_agile_backlog_relation
        ).where(EasyAgileBacklogRelation.arel_table[:id].eq(nil).and(
                IssueEasySprintRelation.arel_table[:id].eq(nil)))

        @issues_for_backlog_query
      end

      def project_backlog_query
        return @project_backlog_query if @project_backlog_query

        @project_backlog_query = query.model.dup
        @sprint_backlog_query.filters = nil
        @project_backlog_query.entity_scope = @scope_was.joins(:easy_agile_backlog_relation).where(
          EasyAgileBacklogRelation.arel_table[:project_id].eq(query.easy_sprint.project_id)
        )
        @project_backlog_query.sort_criteria = []
        @project_backlog_query.use_free_search = false

        @project_backlog_query
      end

      def sprint_backlog_query
        return @sprint_backlog_query if @sprint_backlog_query

        @sprint_backlog_query = query.model.dup
        @sprint_backlog_query.filters = nil
        @sprint_backlog_query.entity_scope = @scope_was.joins(:issue_easy_sprint_relation).where(
          issue_easy_sprint_relations: { relation_type: IssueEasySprintRelation::TYPES[IssueEasySprintRelation::TYPE_BACKLOG],
                                         easy_sprint_id: query.easy_sprint.id }
        )
        @sprint_backlog_query.use_free_search = false

        @sprint_backlog_query
      end

      def kanban_data
        return @kanban_data if @kanban_data

        options = { limit: 50, order: "#{Issue.table_name}.subject asc" }
        @kanban_data = sprint_backlog_query.entities(options)
        @kanban_data.concat(project_backlog_query.entities(options))
        @kanban_data.concat(issues_for_backlog_query.entities(options.merge(limit: 100)))

        @kanban_data
      end

      def before_render
        apply_settings
        restore_settings
      end

      def entity_column_filter_value(entity)
        if entity.easy_agile_backlog_relation.try(:project_id) == query.easy_sprint.project_id
          'project_backlog'
        elsif entity.issue_easy_sprint_relation.try(:easy_sprint_id) == query.easy_sprint.id
          entity.issue_easy_sprint_relation.relation_type
        else
          nil
        end
      end

      def entity_column_position(entity)
        if entity.easy_agile_backlog_relation
          entity.easy_agile_backlog_relation.position
        elsif entity.issue_easy_sprint_relation
          entity.issue_easy_sprint_relation.position
        else
          nil
        end
      end

      def apply_settings
        super
        @scope_was = query.entity_scope unless @scope_was
        at = IssueEasySprintRelation.arel_table
        query.entity_scope = @scope_was.preload(:issue_easy_sprint_relation, :easy_agile_backlog_relation)
            .includes(:issue_easy_sprint_relation, :easy_agile_backlog_relation)
            .references(:issue_easy_sprint_relation, :easy_agile_backlog_relation)
            .where( at[:id].eq(nil).or(
                at[:easy_sprint_id].eq(query.easy_sprint.id).and(at[:relation_type].eq(IssueEasySprintRelation::TYPES[IssueEasySprintRelation::TYPE_BACKLOG]))
              )
            )
      end

      def restore_settings
        super
        query.entity_scope = @scope_was
        query.filters = @filters_was
      end

      def kanban_columns
        [
          {
            name: h.l(:label_issues_for_backlog),
            entity_value: '0',
            positioned: false,
            issues_count: issues_for_backlog_query.entity_count,
            show_issues_count: true,
          },
          {
            name: h.l(:label_project_backlog),
            entity_value: 'project_backlog'
          },
          {
            name: h.l(:label_agile_backlog),
            entity_value: IssueEasySprintRelation::TYPES[IssueEasySprintRelation::TYPE_BACKLOG].to_param
          }
        ]
      end

      def possible_phases(_)
        if allowed_to_edit?
          ['0', 'project_backlog', IssueEasySprintRelation::TYPES[IssueEasySprintRelation::TYPE_BACKLOG].to_s]
        else
          []
        end
      end

      def required_attribute_names(_)
       []
      end

      def read_only_attribute_names(_)
       []
      end

      def allowed_to_edit?
        User.current.allowed_to?(:edit_easy_scrum_board, project)
      end

    end
  end
end
