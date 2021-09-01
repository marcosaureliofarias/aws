module EasyOrgChart
  module EasyIssueQueryPatch
    include EasyOrgChartQueryMixin

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :available_filters, :easy_org_chart
        alias_method_chain :columns_with_me, :easy_org_chart
      end
    end

    module InstanceMethods
      def available_filters_with_easy_org_chart
        available_filters_without_easy_org_chart

        unless @available_filters_with_easy_org_chart_added

          on_filter_group(default_group_label) do
            add_principal_autocomplete_filter 'author_id_supervisor', label: :field_author_id_supervisor,
                                              source: 'all_supervisor_users_values'

            add_principal_autocomplete_filter 'assigned_to_id_supervisor', label: :field_assigned_to_id_supervisor,
                                              source: 'all_supervisor_users_values'
          end

          if User.current.logged? && supervisor_user_ids.include?(User.current.id)
            IssueCustomField.visible.where(field_format: %w[easy_lookup user], is_filter: true).each do |field|
              if field.field_format == 'user' || field.settings[:entity_type] == 'User'
                AddMySubordinatesToUsersFilter.call @available_filters, "cf_#{field.id}"
              end
            end
          end

          @available_filters_with_easy_org_chart_added = true
        end

        @available_filters
      end

      def sql_for_author_id_supervisor_field(field, operator, value)
        sql_for_field_with_supervisor field, operator, value, entity_table_name, 'author_id'
      end

      def sql_for_assigned_to_id_supervisor_field(field, operator, value)
        sql_for_field_with_supervisor field, operator, value, entity_table_name, 'assigned_to_id'
      end

      def columns_with_me_with_easy_org_chart
        columns_with_me_without_easy_org_chart + ['assigned_to_id_supervisor', 'author_id_supervisor']
      end
    end

    module ClassMethods

    end
  end
end

RedmineExtensions::PatchManager.register_model_patch 'EasyIssueQuery', 'EasyOrgChart::EasyIssueQueryPatch'
