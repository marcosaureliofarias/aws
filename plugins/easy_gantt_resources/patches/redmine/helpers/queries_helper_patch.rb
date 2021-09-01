module EasyGanttResources
  module QueriesHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :filters_options_for_select, :easy_gantt_resources

      end
    end

    module InstanceMethods

      def filters_options_for_select_with_easy_gantt_resources(query)
        if query.is_a?(EasyResourceQuery)
          ungrouped = []
          grouped = {}

          user_query_columns = EasyResourceUserQuery.available_columns.collect do |column|
            "user_#{column.name}"
          end
          assigned_to_group_columns = %w(member_of_group assigned_to_role) + user_query_columns

          query.available_filters.map do |field, field_options|
            if [:tree, :relation].include?(field_options[:type])
              group = :label_related_issues
            elsif field =~ /^(.+)\./
              # Association filters
              # group = "field_#{$1}"

              # Not all associated groups are translated
              group = :label_custom_field_plural
            elsif assigned_to_group_columns.include?(field)
              group = :field_assigned_to
            elsif field_options[:type] == :date_past || field_options[:type] == :date
              group = :label_date
            end
            if group
              (grouped[group] ||= []) << [field_options[:name], field]
            else
              ungrouped << [field_options[:name], field]
            end
          end
          # Don't group dates if there's only one (eg. time entries filters)
          if grouped[:label_date].try(:size) == 1
            ungrouped << grouped.delete(:label_date).first
          end
          s = options_for_select([[]] + ungrouped)
          if grouped.present?
            localized_grouped = grouped.map {|k,v| [l(k), v]}
            s << grouped_options_for_select(localized_grouped)
          end
          s
        else
          filters_options_for_select_without_easy_gantt_resources(query)
        end
      end

    end

  end
end
RedmineExtensions::PatchManager.register_helper_patch 'QueriesHelper', 'EasyGanttResources::QueriesHelperPatch'
