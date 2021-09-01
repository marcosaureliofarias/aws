module EasyOrgChart
  module EasyUserQueryPatch
    include EasyOrgChartQueryMixin
    
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :available_filters, :easy_org_chart
        alias_method_chain :available_columns, :easy_org_chart
        alias_method_chain :columns_with_me, :easy_org_chart

      end
    end

    module InstanceMethods
      def available_filters_with_easy_org_chart
        available_filters_without_easy_org_chart
        
        unless @available_filters_with_easy_org_chart_added

          on_filter_group(default_group_label) do
            add_principal_autocomplete_filter 'supervisor_id', label: :field_supervisor,
                                              source: 'all_supervisor_users_values'
          end

          @available_filters_with_easy_org_chart_added = true
        end
        
        @available_filters
      end
      
      def available_columns_with_easy_org_chart
        available_columns_without_easy_org_chart

        unless @available_columns_with_easy_org_chart_added
          @available_columns << EasyQueryColumn.new(:supervisor, groupable: "supervisors_users.id", group: default_group_label, includes: [:supervisor])

          @available_columns_with_easy_org_chart_added = true
        end

        @available_columns
      end
      
      def sql_for_supervisor_id_field(field, operator, value)
        sql_for_field_with_supervisor field, operator, value, entity_table_name, 'id'
      end

      def columns_with_me_with_easy_org_chart
        columns_with_me_without_easy_org_chart + ['supervisor_id']
      end
    end

    module ClassMethods

    end
  end
end

RedmineExtensions::PatchManager.register_model_patch 'EasyUserQuery', 'EasyOrgChart::EasyUserQueryPatch'
