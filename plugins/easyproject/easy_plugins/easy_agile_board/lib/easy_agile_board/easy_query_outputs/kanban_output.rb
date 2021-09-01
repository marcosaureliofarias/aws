module EasyAgileBoard
  module EasyQueryOutputs
    class KanbanOutput < EasyExtensions::EasyQueryHelpers::EasyQueryOutput

      AVAILABLE_FOR = ['EasyIssueQuery']
      ISSUES_AVAILABLE_GROUPS = ['status', 'tracker']

      # Ondra quick hack
      def self.available_for?(query)
        AVAILABLE_FOR.include?(query.class.name)
      end

      def self.default_column_names
        column_names = %w(assigned_to status subject tracker project start_date due_date priority author fixed_version done_ratio estimated_hours total_estimated_hours parent spent_hours total_spent_hours)
        column_names.push('category', 'parent_category', 'root_category') unless EasyExtensions::EasyProjectSettings.disabled_features[:others].include?('issue_categories')
        column_names
      end

      def configured?
        query.grouped? && query.group_by_column.count <= 2
      end

      # Ondra quick hack
      def all_issue_statuses
        @all_issue_statuses ||= IssueStatus.sorted.to_a
      end

      def apply_settings
        @group_by_was = query.group_by
        @columns_was = query.column_names
        query.group_by = Array.wrap(kanban_output_settings['kanban_group']) if kanban_output_settings['kanban_group']
        if query.has_default_columns?
          query.column_names = self.default_column_names
        else
          query.column_names |= self.default_column_names
        end
      end

      def restore_settings
        query.group_by = @group_by_was
        query.column_names = @columns_was
      end

      def configure_from_defaults
        kanban_output_settings['kanban_group'] = Array.wrap(self.group_by)[0..1]
      end

      def order
        500
      end

      # Ondra quick hack
      # Keep number just to prevent undefined method on NilClass
      # (was 100)
      def entity_limit
        9_999_999
      end

      def default_column_names
        kanban_output_settings.slice('kanban_group', 'main_attribute', 'avatar_attribute', 'summable_column', 'date_details', 'icon_details').values.flatten
      end

      def kanban_groups
        @kanban_groups ||= query.groups
      end

      def avatar_column
        @avatar_column ||= query.get_column(kanban_output_settings['avatar_attribute'])
      end

      def kanban_data
        @kanban_data ||= query.entities(fetch: true, limit: entity_limit)
      end

      def kanban_output_settings
        query.settings['kanban'] || {}
      end

      def entity_column_filter_value(entity)
        query.group_by_column.first.value(entity).to_param
      end

      def columns_from_attributes(attributes)
        attributes.collect do |attr|
          query.get_column(attr)
        end.compact if attributes.is_a?(Array)
      end

      def entity_json(entity)
        res = super.merge(entity_name: entity.to_s, show_path: (h.polymorphic_path(entity) rescue nil), agile_column_filter_value: entity_column_filter_value(entity))
        res[:css_classes] = entity.css_classes if entity.respond_to?(:css_classes)

        # Ondra quick hack
        if query.type == 'EasyIssueQuery' && query.group_by.first == 'status'
          res[:possible_phases] = all_issue_statuses.map{|s| s.id.to_s }
        else
          res[:possible_phases] = kanban_groups.keys.map(&:to_s)
        end

        res[:required_attribute_names] = []
        res[:read_only_attribute_names] = []
        avatar_id = avatar_column && avatar_column.value(entity)
        res[:avatar] = h.avatar(avatar_id, style: :small) if avatar_id
        icon_cols = columns_from_attributes(kanban_output_settings['icon_details'])
        res[:icon_classes] = icon_cols.collect{|col| col.value(entity).try(:easy_icon) }.compact if icon_cols
        swimlanes.each do |swimlane|
          next unless entity.respond_to?(swimlane[:value])
          if swimlane[:value] == 'fixed_version_id'
            res['fixed_version_id'] = entity.fixed_version && entity.fixed_version.closed? ? nil : entity.fixed_version_id
          else
            res[swimlane[:value]] = entity.send(swimlane[:value])
          end
        end
        res
      end

      def api_data_grouped
        data = query.groups(include_entities: true)
        data.keys.inject({}) do |memo, group|
          current = memo
          if group.is_a?(Array)
            group[0..-2].each do |grp|
              current = current[grp] ||= {}
            end
            grp = group.last
          else
            grp = group
          end
          current[grp] = []
          data[group][:entities].each do |entity|
            current[grp] << entity_json(entity)
          end
          memo
        end
      end

      def project
        query.project
      end

      def swimlanes
        return @swimlanes if @swimlanes
        @swimlanes = EasyIssueQuery.available_swimlanes
        if project
          @swimlanes.delete_if{|swimlane| swimlane[:value] == 'project_id' }
        else
          @swimlanes.delete_if{|swimlane| swimlane[:value] == 'category_id' }
        end

        @swimlanes
      end

      def project_members_for_kanban(project_id)
        users, groups = [], []
        assigned_ids = kanban_data.collect(&:assigned_to_id).compact.uniq
        users_and_groups = Principal.preload(Setting.gravatar_enabled? ? :email_address : :easy_avatar)
                               .joins(:members)
                               .where(Member.arel_table[:project_id].eq(project_id).or(Principal.arel_table[:id].in(assigned_ids)))
                               .active.visible.sorted.distinct.to_a

        users_and_groups.each do |principal|
          if principal.is_a?(User)
            users << { id: principal.id, name: principal.to_s, type: 'user', avatar: h.avatar(principal, style: :small) }
          else
            groups << { id: principal.id, name: principal.to_s, type: 'group', avatar: h.avatar(principal, style: :small) }
          end
        end

        users + groups
      end

      def kanban_columns
        result = []

        # Ondra quick hack
        case [query.type, query.group_by.first]
          when ['EasyIssueQuery', 'status']
            statuses = IssueStatus.sorted
            statuses = statuses.where(id: kanban_output_settings['kanban_group_statuses']) if kanban_output_settings['kanban_group_statuses'].present?
            statuses.each do |status|
            result << {
              name: status.name,
              entity_value: status.id.to_s,
              max_entities: nil
            }
            end
          when ['EasyIssueQuery', 'tracker']
            trackers = Tracker.visible.sorted
            trackers = trackers.where(id: kanban_output_settings['kanban_group_trackers']) if kanban_output_settings['kanban_group_trackers'].present?
            trackers.each do |tracker|
            result << {
                name: tracker.name,
                entity_value: tracker.id.to_s,
                max_entities: nil
            }
            end
        else
          kanban_groups.each do |group, attributes|
            result << {
                name: h.format_groupby_entity_attribute(query.entity, query.group_by_column, attributes[:name], entity: attributes[:entity], no_link: true, no_html: true),
                entity_value: group.to_param,
                max_entities: nil
              }
          end
        end

        [{}, { children: result }, {}]
      end

      def api_data
        kanban_data.collect{|entity| entity_json(entity) }
      end

      def kanban_settings
        col_name = query.group_by_column.first.name.to_s
        col_name = col_name + '_id' if !query.entity.column_names.include?(col_name) && query.entity.column_names.include?(col_name + '_id')
        {
          summable_attribute: {numerator: { attr: "#{kanban_output_settings['summable_column']}_raw".presence}, denominator: {} },
          swimlane_categories: swimlanes,
          update_params_prefix: query.entity.name.underscore,
          assign_param_name: col_name,
          template_card: h.capture{ h.render partial: 'easy_kanban/entity_card', locals: { output: self, settings: kanban_output_settings}, formats: [:mustache] },
          template_column_name: h.capture{ h.render partial: 'easy_kanban/kanban_column_name', formats: [:mustache], locals: { query: query, summable_column: kanban_output_settings['summable_column'] } },
          project_members: [],
          available_values_url: h.url_for(query.to_params.merge(controller: 'easy_agile_data', action: 'swimlane_values', project_id: project, only_path: true)),
          context_menu_path: h.issues_context_menu_path
        }
      end

      # def columns_data
      #   column = query.group_by_column.first
      #   values = column.values.is_a?(Proc) ? column.values.call : column.values
      #   values.inject({}) do |memo, val|
      #     memo[val.is_a?(ActiveRecord::Base) ? val.id : val.to_s] = val.to_s
      #   end
      # end

      def i18n
        {
          not_assigned: h.l(:label_not_assigned),
          issue_without_parent: h.l(:label_without_parent),
          internal_error: h.l(:error_default_server_error),
          you_are_offline: h.l(:text_you_are_offline, scope: :easy_agile_board),
          attibute_undefined: h.l(:attribute_undefined),
          issue_no_in_milestone: h.l(:label_without_milestone),
          not_authorized: h.l(:notice_not_authorized),
          without_category: h.l(:label_without_category),
          sprint: h.l(:field_easy_sprint),
          swimlane: h.l(:label_swimlane)
        }
      end

      def render_api_data(api, options)
        @options = options
        apply_settings
        api.columns kanban_columns
        api.settings kanban_settings
        api.entities api_data
        api.i18n i18n
      ensure
        restore_settings
      end

      def edit_form
        'easy_queries/kanban_output_settings'
      end

    end
  end
end
