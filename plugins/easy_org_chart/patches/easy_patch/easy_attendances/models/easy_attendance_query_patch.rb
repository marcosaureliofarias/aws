module EasyOrgChart
  module EasyAttendanceQueryPatch
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
            add_principal_autocomplete_filter 'subordinates_of_supervisor', label: :field_subordinates_of_supervisor,
                                              order: 20,
                                              source: 'all_supervisor_users_values'
          end

          if @available_filters['user_id'] && User.current.logged? && supervisor_user_ids.include?(User.current.id)
            AddMySubordinatesToUsersFilter.call(@available_filters, 'user_id')
          end

          @available_filters_with_easy_org_chart_added = true
        end

        @available_filters
      end

      def columns_with_me_with_easy_org_chart
        columns_with_me_without_easy_org_chart + ['subordinates_of_supervisor']
      end

      def sql_for_subordinates_of_supervisor_field(field, operator, value)
        sql_for_field_with_supervisor field, operator, value, entity_table_name, 'user_id'
      end
    end

    module ClassMethods

    end
  end
end

RedmineExtensions::PatchManager.register_model_patch 'EasyAttendanceQuery', 'EasyOrgChart::EasyAttendanceQueryPatch', if: -> {Redmine::Plugin.installed? :easy_attendances}
