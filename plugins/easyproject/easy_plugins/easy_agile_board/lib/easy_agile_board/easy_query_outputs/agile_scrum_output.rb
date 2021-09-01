module EasyAgileBoard
  module EasyQueryOutputs
    class AgileScrumOutput < KanbanOutput

      def self.key
        'scrum'
      end

      def kanban_statuses
        statuses = EasySetting.value('agile_board_statuses', project) || {}
        statuses = statuses.to_unsafe_hash if statuses.respond_to?(:to_unsafe_hash)
        statuses.symbolize_keys
      end

      def kanban_output_settings
        saved_settings = EasySetting.value('scrum_output_setting', project) || {}
        saved_settings = saved_settings.to_unsafe_hash if saved_settings.respond_to?(:to_unsafe_hash)

        {
            'kanban_group' => 'scrum_phase',
            'capacity_attribute' => query.easy_sprint.capacity_attribute
        }.merge(saved_settings)
      end

      def self.default_column_names
        super << 'scrum_phase'
      end

      def default_column_names
        super.concat(self.class.default_column_names).uniq
      end

      def kanban_setting_for(phase_type, subcolumn = nil)
        res = (kanban_statuses[phase_type] || {})
        subcolumn = subcolumn.to_s if !subcolumn.nil? && !res.key?(subcolumn) && res.key?(subcolumn.to_s)
        res = res[subcolumn] if subcolumn
        res || {}
      end

      def kanban_status_ids_for(phase_type, subcolumn = nil)
        (kanban_setting_for(phase_type, subcolumn)['state_statuses'] || []).collect{|sid| sid.to_i }
      end

      def entity_column_position(entity)
        entity.issue_easy_sprint_relation && entity.issue_easy_sprint_relation.position
      end

      def entity_json(entity)
        super.merge(
          easy_story_points: entity.easy_story_points,
          easy_story_points_raw: entity.easy_story_points,
          read: !entity.unread?,
          edit_path: h.assign_issue_project_easy_sprint_path(project, query.easy_sprint, issue_id: entity),
          show_path: h.issue_path(entity),
          agile_column_position: entity_column_position(entity),
          possible_phases:  possible_phases(entity),
          required_attribute_names: required_attribute_names(entity),
          read_only_attribute_names: read_only_attribute_names(entity)
        )
      end

      def possible_phases(entity)
        IssueEasySprintRelation.kanban_phase_for_statuses(entity, project, use_workflow?)
      end

      def required_attribute_names(entity)
        use_workflow? ? entity.required_attribute_names(User.current) : []
      end

      def read_only_attribute_names(entity)
        use_workflow? ? entity.read_only_attribute_names(User.current) : []
      end

      def use_workflow?
        @use_workflow ||= EasySetting.value('easy_agile_use_workflow_on_sprint', project)
      end

      def apply_settings
        super
        @scope_was = query.entity_scope
        @filters_was = query.filters.dup
        if query.respond_to?(:only_assigned) && query.only_assigned
          query.filters.slice!('assigned_to_id')
        else
          query.filters = {}
        end
        query.entity_scope = @scope_was.joins(:issue_easy_sprint_relation).where(issue_easy_sprint_relations: { easy_sprint_id: query.easy_sprint.id })
        query.sort_criteria = [['scrum_phase', 'asc']]
        sprint = query.easy_sprint
        if sprint.display_closed_tasks_in_last_n_days.present?
          done_phase = IssueEasySprintRelation::TYPES[IssueEasySprintRelation::TYPE_DONE]
          end_datetime = sprint.current_time_for_display_closed_tasks_in_last_n_days
          date_range = { from: end_datetime.beginning_of_day - sprint.display_closed_tasks_in_last_n_days.days, to: end_datetime }
          issue_easy_sprint_relations = IssueEasySprintRelation.arel_table

          issues = Issue.arel_table
          query.entity_scope = query.entity_scope.where(
            issue_easy_sprint_relations[:relation_type].not_eq(done_phase).or(
              issues[:closed_on].eq(nil).or(
                issues[:closed_on].gt(date_range[:from]).and(
                  issues[:closed_on].lteq(date_range[:to])
                )
              )
            )
          )
        end
      end

      def kanban_column_name(phase_type, phase_position)
        case phase_type
        when IssueEasySprintRelation::TYPE_BACKLOG
          h.l(:label_agile_backlog)
        when IssueEasySprintRelation::TYPE_PROGRESS
          if phase_position.nil?
            h.l(:label_agile_in_progress)
          else
            kanban_setting_for(IssueEasySprintRelation::TYPE_PROGRESS, phase_position)['name']
          end
        when IssueEasySprintRelation::TYPE_DONE
          h.l(:label_agile_done)
        end
      end

      def project
        query.easy_sprint.project
      end

      def kanban_settings
        super.merge({
          current_sprint: query.easy_sprint,
          sprint_autocomplete_url: h.autocomplete_project_easy_sprints_path(project, format: :json),
          update_params_prefix: 'issue_easy_sprint_relation',
          assign_param_name: 'phase',
          available_values_url: available_values_url,
          context_menu_path: h.issues_context_menu_path,
          project_members: project_members_for_kanban(query.easy_sprint.project_id),
          trackers: Tracker.sorted.collect{|tracker| { id: tracker.id, name: tracker.to_s, css_class: tracker.easy_icon } },
          reorder_path: h.easy_scrum_reorder_path(project, query.easy_sprint),
          template_tooltip: h.capture{ h.render partial: 'easy_kanban/tooltip_entity_card', formats: [:mustache] },
          issue_priorities: IssuePriority.active.reorder(position: :desc).pluck(:id),
          issue_parents_not_in_kanban: (kanban_data.collect(&:parent) - kanban_data).compact.uniq.collect{|entity| entity_json(entity) },
          summable_attribute: rating_settings_for_kanban(kanban_output_settings['summable_column']),
          sum_easy_agile_rating: query.easy_sprint.sum_easy_agile_rating,
          capacity: query.easy_sprint.capacity,
          capacity_attribute: query.easy_sprint.capacity_attribute,
          capacity_attribute_form: h.capture{ h.render partial: 'easy_agile_board/capacity_attribute_form', formats: [:mustache], locals: { capacity_attribute: query.easy_sprint.capacity_attribute.to_s } },
          check_capacities: @options && @options[:check_capacities]
        })
      end

      def rating_settings_for_kanban(mode)
        return unless mode
        {numerator: { attr: "#{mode}_raw"}, denominator: { attr: "#{mode}_raw", scope: :all } }
      end

      def kanban_column_definition(phase_type, phase_position = nil)
        if phase_position.nil? && phase_type == IssueEasySprintRelation::TYPE_PROGRESS
          {
            name: h.l(:label_agile_in_progress),
            children: kanban_setting_for(phase_type).keys.collect{|position| kanban_column_definition(phase_type, position.to_i) }
          }
        else
          {
            name: kanban_column_name(phase_type, phase_position),
            entity_value: (phase_position || IssueEasySprintRelation::TYPES[phase_type]).to_param,
            max_entities: nil
          }
        end
      end

      def kanban_columns
        # super does not work properly - leaves out unused columns
        # super.each do |column|
        #   column[:max_entities] = 0
        # end
        show_backlog = true
        types = IssueEasySprintRelation::TYPES.dup
        types.delete(IssueEasySprintRelation::TYPE_BACKLOG) unless show_backlog

        types.keys.collect do |phase_type|
          kanban_column_definition(phase_type)
        end
      end

      def swimlanes
        return @swimlanes if @swimlanes
        @swimlanes = EasyIssueQuery.available_swimlanes
        @swimlanes.delete_if{|swimlane| swimlane[:value] == 'project_id' } unless query.easy_sprint.cross_project?
        @swimlanes
      end

      private

      def available_values_url
        url_params = query.to_params.merge(controller: 'easy_agile_data', action: 'swimlane_values', only_path: true)
        url_params[:project_id] = project.id unless query.easy_sprint.cross_project?

        h.url_for(url_params)
      end

    end
  end
end
