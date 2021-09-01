module EasyAgileBoard
  module EasyIssueQueryPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :initialize_available_filters, :easy_agile_board
        alias_method_chain :initialize_available_columns, :easy_agile_board

        # Creates more compact params to address long URL issues
        # @param [Hash] params
        def shrink_params(params)
          return if params.nil?

          params = super

          if params[:settings].is_a?(Hash) && settings['kanban'].is_a?(Hash) && !params[:export]
            params[:settings][:kanban] = settings['kanban'].dup
            params[:settings][:kanban].each do |key, values|
              next unless values.is_a?(Array)
              params[:settings][:kanban][key] = Array.wrap(values.join('|'))
            end
          end
          params
        end

        # Parses compact params into standard format
        # @param [Hash] params
        def expand_params(params)
          return if params.nil?

          if params[:settings].is_a?(Hash) && params[:settings].key?(:kanban)
            params[:settings][:kanban].each do |key, values|
              next unless values.is_a?(Array)
              params[:settings][:kanban][key] = values.map {|value| value.split('|') }.flatten
            end
          end
          super(params)
        end

        def sql_for_easy_sprint_id_field(field, operator, value)
          sql = '('
          sql << sql_for_field(field, operator, value, IssueEasySprintRelation.table_name, 'easy_sprint_id')
          sql << ')'
          sql
        end

        def available_swimlanes
          self.class.available_swimlanes
        end

        def projects_with_easy_scrum_board
          Project.visible.has_module(:easy_scrum_board).sorted.pluck(:name, :id)
        end

        class << self

          def available_swimlanes
            [
              { value: 'none', name: l(:label_without_swimlane) },
              { value: 'assigned_to_id', name: l(:field_assigned_to) },
              { value: 'priority_id', name: l(:field_priority) },
              { value: 'tracker_id', name: l(:field_tracker) },
              { value: 'author_id', name: l(:field_author) },
              { value: 'fixed_version_id', name: l(:field_version) },
              { value: 'parent_id', name: l(:field_parent_issue) },
              { value: 'category_id', name: l(:field_category) },
              { value: 'easy_sprint_id', name: l(:field_easy_sprint) },
              { value: 'project_id', name: l(:field_project) }
            ]
          end

        end

      end
    end

    module InstanceMethods
      def initialize_available_filters_with_easy_agile_board
        initialize_available_filters_without_easy_agile_board

        group = l('easy_query.name.easy_agile_board_query')
        on_filter_group(group) do
          add_available_filter 'easy_sprint_id', {
            type: :list_optional,
            data_type: :sprint,
            order: 1,
            values: proc { EasyAgileBoard.easy_sprints_for_autocomplete(project) },
            includes: [:issue_easy_sprint_relation]
          }
          add_available_filter 'easy_story_points', { type: :integer, order: 2 }

          add_available_filter 'easy_sprints.project_id', {
              type: :list_optional,
              includes: :easy_sprint,
              values: proc { projects_with_easy_scrum_board },
              name: l(:label_sprints_project),
              data_type: :project
          }

          add_available_filter 'easy_project_backlog', {
            type: :list_optional,
            label: :label_project_backlog,
            includes: [:easy_agile_backlog_relation],
            values: proc { projects_with_easy_scrum_board },
            data_type: :project,
            attr_writer: true
          }
        end
      end

      def sql_for_easy_project_backlog_field(field, operator, value)
        sql_for_field(field, operator, value, EasyAgileBacklogRelation.table_name, 'project_id')
      end

      def initialize_available_columns_with_easy_agile_board
        initialize_available_columns_without_easy_agile_board

        group = l('easy_query.name.easy_agile_board_query')
        @available_columns << EasyQueryColumn.new(:'issue_easy_sprint_relation.easy_sprint', groupable: "#{EasySprint.table_name}.id", sortable: "#{EasySprint.table_name}.name", caption: :label_agile_sprint, includes: [issue_easy_sprint_relation: :easy_sprint], group: group)
        @available_columns << EasyQueryColumn.new(:easy_story_points, groupable: true, sumable: :both, sortable: "#{Issue.table_name}.easy_story_points", caption: :label_agile_story_points, group: group)
      end
    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'EasyIssueQuery', 'EasyAgileBoard::EasyIssueQueryPatch'

