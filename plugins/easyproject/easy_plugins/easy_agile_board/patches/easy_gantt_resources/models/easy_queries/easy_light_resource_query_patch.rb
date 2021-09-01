module EasyAgileBoard
  module EasyLightResourceQueryPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :initialize_available_filters, :easy_agile_board
      end
    end

    module InstanceMethods
      def initialize_available_filters_with_easy_agile_board
        initialize_available_filters_without_easy_agile_board

        issues_groups = l('label_filter_group_easy_issue_query')
        on_filter_group(issues_groups) do
          add_available_filter 'issues.easy_sprint_id', type: :list_optional,
                                                        joins: [issue: :issue_easy_sprint_relation],
                                                        data_type: :sprint,
                                                        label: :field_easy_sprint,
                                                        order: 1,
                                                        values: -> { EasyAgileBoard.easy_sprints_for_autocomplete(project) }
        end
      end
    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'EasyLightResourceQuery', 'EasyAgileBoard::EasyLightResourceQueryPatch', if: -> { Redmine::Plugin.installed?(:easy_gantt_resources) }

