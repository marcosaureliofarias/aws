module EasyAgileBoard
  module EasyQueryOutputs
    class AgileKanbanOutput < KanbanOutput

      include EasyIconsHelper

      def self.key
        'kanban'
      end

      def self.default_column_names
        super << 'kanban_phase'
      end

      def default_column_names
        super.concat(self.class.default_column_names).uniq
      end

      def kanban_statuses
        statuses = EasySetting.value('kanban_statuses', query.project) || {}
        statuses = statuses.to_unsafe_hash if statuses.respond_to?(:to_unsafe_hash)
        statuses.symbolize_keys
      end

      def kanban_output_settings
        saved_settings = EasySetting.value('kanban_output_setting', query.project) || {}
        saved_settings = saved_settings.to_unsafe_hash if saved_settings.respond_to?(:to_unsafe_hash)

        { 'kanban_group' => 'kanban_phase' }.merge(saved_settings)
      end

      def kanban_setting_for(phase_type, subcolumn = nil)
        res = (kanban_statuses[phase_type] || {})
        res = res[subcolumn.to_i] || res[subcolumn.to_s] if subcolumn
        res || {}
      end

      def kanban_status_ids_for(phase_type, subcolumn = nil)
        (kanban_setting_for(phase_type, subcolumn)['state_statuses'] || []).collect{|sid| sid.to_i }
      end

      def entity_column_position(entity)
        entity.easy_kanban_issue(query.project) && entity.easy_kanban_issue(query.project).position
      end

      def entity_json(entity)
        super.merge(edit_path: h.issue_easy_kanban_issue_path(query.project, entity),
                    read: !entity.unread?,
                    agile_column_position: entity_column_position(entity),
                    possible_phases: possible_phases(entity),
                    required_attribute_names: required_attribute_names(entity),
                    read_only_attribute_names: read_only_attribute_names(entity)
        )
      end

      def possible_phases(entity)
        EasyKanbanIssue.kanban_phase_for_statuses(entity, query.project, use_workflow?)
      end

      def required_attribute_names(entity)
        use_workflow? ? entity.required_attribute_names(User.current) : []
      end

      def read_only_attribute_names(entity)
        use_workflow? ? entity.read_only_attribute_names(User.current) : []
      end

      def use_workflow?
        @use_workflow ||= EasySetting.value('easy_agile_use_workflow_on_kanban', project)
      end

      def apply_settings
        super
        @scope_was = query.entity_scope
        @filters_was = query.filters.dup
        query.filters.slice!('assigned_to_id')
        query.sort_criteria = [['kanban_phase', 'asc']]
        query.entity_scope = @scope_was.with_kanban_issues_of_project(query.project)
        if (last_n_days = EasySetting.value('kanban_display_closed_tasks_in_last_n_days', project))
          done_phase = EasyKanbanIssue::TYPES[EasyKanbanIssue::TYPE_DONE]
          end_datetime = query.entity.default_timezone == :utc ? Time.now.utc : Time.now
          date_range = { from: end_datetime.beginning_of_day - last_n_days.to_f.days, to: end_datetime }
          issue_kanban_relations = EasyKanbanIssue.arel_table

          issues = Issue.arel_table
          query.entity_scope = query.entity_scope.where(
            issue_kanban_relations[:phase].not_eq(done_phase).or(
              issues[:closed_on].eq(nil).or(
                issues[:closed_on].gt(date_range[:from]).and(
                  issues[:closed_on].lteq(date_range[:to])
                )
              )
            )
          )
        end
      end

      def restore_settings
        super
        query.entity_scope = @scope_was
        query.filters = @filters_was
      end

      def kanban_column_name(phase_type, phase_position)
        case phase_type
        when EasyKanbanIssue::TYPE_BACKLOG
          h.l(:label_project_backlog)
        when EasyKanbanIssue::TYPE_PROGRESS
          if phase_position.nil?
            h.l(:label_agile_in_progress)
          else
            kanban_setting_for(EasyKanbanIssue::TYPE_PROGRESS, phase_position)['name']
          end
        when EasyKanbanIssue::TYPE_DONE
          h.l(:label_agile_done)
        end
      end

      def kanban_column_definition(phase_type, phase_position = nil)
        if phase_position.nil? && phase_type == EasyKanbanIssue::TYPE_PROGRESS
          {
            name: h.l(:label_agile_in_progress),
            children: kanban_setting_for(phase_type).keys.collect{|position| kanban_column_definition(phase_type, position.to_i) }
          }
        else
          {
            name: kanban_column_name(phase_type, phase_position),
            entity_value: (phase_position || EasyKanbanIssue::TYPES[phase_type]).to_param,
            max_entities: nil
          }
        end
      end

      def kanban_settings
        super.merge({
          update_params_prefix: 'easy_kanban_issue',
          assign_param_name: 'phase',
          available_values_url: h.url_for(query.to_params.merge(controller: 'easy_agile_data', action: 'swimlane_values', project_id: query.project, only_path: true)),
          context_menu_path: h.issues_context_menu_path,
          project_members: project_members_for_kanban(query.project_id),
          trackers: Tracker.sorted.collect{|tracker| { id: tracker.id, name: tracker.to_s, css_class: tracker.easy_icon } },
          reorder_path: h.easy_kanban_reorder_path(query.project),
          template_tooltip: h.capture{ h.render partial: 'easy_kanban/tooltip_entity_card', formats: [:mustache] },
          issue_priorities: IssuePriority.active.reorder(position: :desc).pluck(:id),
          issue_parents_not_in_kanban: (kanban_data.collect(&:parent) - kanban_data).compact.uniq.collect{|entity| entity_json(entity) }
        })
      end

      def kanban_columns
        # super does not work properly - leaves out unused columns
        # super.each do |column|
        #   column[:max_entities] = 0
        # end
        show_backlog = true
        phases = EasyKanbanIssue::TYPES.dup
        phases.delete(EasyKanbanIssue::TYPE_NOT_ASSIGNED)
        phases.delete(EasyKanbanIssue::TYPE_BACKLOG) unless show_backlog

        phases.keys.collect do |phase_type|
          kanban_column_definition(phase_type)
        end
      end

    end
  end
end
