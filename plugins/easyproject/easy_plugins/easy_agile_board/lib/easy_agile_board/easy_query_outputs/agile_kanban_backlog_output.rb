module EasyAgileBoard
  module EasyQueryOutputs
    class AgileKanbanBacklogOutput < AgileKanbanOutput

      def self.key
        'agile_backlog'
      end

      def kanban_data
        return @kanban_data if @kanban_data
        saved_scope = @scope_was
        saved_use_search = query.use_free_search
        saved_filters = @filters_was
        query.filters = nil
        options = { fetch: true, limit: 100, order: "#{Issue.table_name}.subject asc" }
        query.entity_scope = saved_scope.joins("INNER JOIN easy_kanban_issues as eki on issues.id = eki.issue_id AND eki.project_id = #{query.project_id}")
                                        .where(eki: { phase: EasyKanbanIssue::TYPES[EasyKanbanIssue::TYPE_BACKLOG] })
        query.use_free_search = false
        @kanban_data = query.entities(options.dup)
        query.filters = saved_filters
        query.entity_scope = saved_scope.joins("LEFT OUTER JOIN easy_kanban_issues as eki on issues.id = eki.issue_id AND eki.project_id = #{query.project_id}")
                                        .where(eki: { phase: [nil, EasyKanbanIssue::TYPES[EasyKanbanIssue::TYPE_NOT_ASSIGNED]] })
        query.use_free_search = saved_use_search
        query.sort_criteria = []
        query.instance_variable_set(:@entities, nil)
        query.model.instance_variable_set(:@additional_scope, nil)
        @kanban_data.concat(query.entities(options.dup))
      end

      def kanban_columns
        [
          { name: h.l(:label_issues_for_backlog), entity_value: EasyKanbanIssue::TYPES[EasyKanbanIssue::TYPE_NOT_ASSIGNED].to_param, positioned: false },
          { name: h.l(:label_project_backlog), entity_value: EasyKanbanIssue::TYPES[EasyKanbanIssue::TYPE_BACKLOG].to_param }
        ]
      end

      def before_render
        apply_settings
        restore_settings
      end

      def apply_settings
        super
        at = EasyKanbanIssue.arel_table
        query.entity_scope = @scope_was.where(at[:phase].eq(nil).or(at[:phase].eq(EasyKanbanIssue::TYPES[EasyKanbanIssue::TYPE_BACKLOG])))
      end

      def possible_phases(_)
        if allowed_to_edit?
          [EasyKanbanIssue::TYPES[EasyKanbanIssue::TYPE_NOT_ASSIGNED].to_s, EasyKanbanIssue::TYPES[EasyKanbanIssue::TYPE_BACKLOG].to_s]
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
        User.current.allowed_to?(:edit_easy_kanban_board, project)
      end

    end
  end
end
