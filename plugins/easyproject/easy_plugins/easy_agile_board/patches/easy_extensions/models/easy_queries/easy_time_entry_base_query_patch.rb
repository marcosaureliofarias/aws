module EasyAgileBoard
  module EasyTimeEntryBaseQueryPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :initialize_available_filters, :easy_agile_board
        alias_method_chain :available_columns, :easy_agile_board

        def sql_for_easy_sprint_id_field(field, operator, value)
          sql = '('
          sql << sql_for_field(field, operator, value, IssueEasySprintRelation.table_name, 'easy_sprint_id')
          sql << ')'
          sql
        end

      end
    end

    module InstanceMethods

      def initialize_available_filters_with_easy_agile_board
        initialize_available_filters_without_easy_agile_board

        add_available_filter 'easy_sprint_id', {
          type: :list_optional,
          order: 1,
          data_type: :sprint,
          includes: [issue: :issue_easy_sprint_relation],
          group: l('easy_query.name.easy_agile_board_query'),
          values: proc { EasyAgileBoard.easy_sprints_for_autocomplete(project) }
        }
      end

      def available_columns_with_easy_agile_board
        unless @available_columns_with_easy_agile_board
          available_columns_without_easy_agile_board
          group = l('easy_query.name.easy_agile_board_query')
          @available_columns << EasyQueryColumn.new(:'issue.issue_easy_sprint_relation.easy_sprint', groupable: "#{EasySprint.table_name}.id", sortable: "#{EasySprint.table_name}.name", caption: :label_agile_sprint, includes: [issue: { issue_easy_sprint_relation: :easy_sprint }], group: group)
          @available_columns_with_easy_agile_board = true
        end
        @available_columns
      end
    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'EasyTimeEntryBaseQuery', 'EasyAgileBoard::EasyTimeEntryBaseQueryPatch'
