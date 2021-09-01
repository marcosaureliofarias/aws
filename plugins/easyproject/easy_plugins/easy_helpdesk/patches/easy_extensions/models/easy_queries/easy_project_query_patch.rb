module EasyHelpdesk
  module EasyProjectQueryPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :initialize_available_filters, :easy_helpdesk
        alias_method_chain :initialize_available_columns, :easy_helpdesk

        def sql_for_aggregated_hours_field(field, operator, value)
          sql = "#{entity_table_name}.id IN (SELECT ehp1.project_id FROM #{EasyHelpdeskProject.table_name} ehp1 WHERE "
          sql << sql_for_field(field, operator, value, 'ehp1', field) << ')'
          sql
        end

        alias_method :sql_for_aggregated_hours_remaining_field, :sql_for_aggregated_hours_field

        def sql_for_easy_helpdesk_maintained_field(field, operator, value)
          "#{(Array(value).include?('1')) ? '' : 'NOT '}EXISTS (SELECT ehp.id FROM #{EasyHelpdeskProject.table_name} ehp WHERE ehp.project_id = #{entity_table_name}.id)"
        end

        def helpdesk_spent_time_sum_sql(period)
          range = self.get_date_range('1', period)
          from = range[:from]
          to = range[:to]
          time_range_condition = "(ehpt.spent_on BETWEEN '#{from}' AND '#{to}') AND " if from.present? && to.present?
          "COALESCE((SELECT SUM(ehpt.hours) FROM #{TimeEntry.table_name} ehpt JOIN #{Issue.table_name} ehpi ON ehpt.issue_id = ehpi.id INNER JOIN #{EasyHelpdeskProject.table_name} ehp ON ehpt.project_id = ehp.project_id WHERE #{time_range_condition}ehpt.project_id = #{entity_table_name}.id AND ehpi.tracker_id in (SELECT tracker_id FROM #{Tracker.table_name} INNER JOIN #{Project.table_name}_#{Tracker.table_name} ON #{Tracker.table_name}.id = #{Project.table_name}_#{Tracker.table_name}.tracker_id WHERE #{Project.table_name}_#{Tracker.table_name}.project_id = ehpt.project_id)), 0)"
        end

        def helpdesk_spent_time_filter_sql(field, operator, value, period)
          db_field = helpdesk_spent_time_sum_sql(period)
          o = value.first == '1' ? '=' : '<>'
          "#{db_field} #{o} 0"
        end

        def sql_for_spent_time_current_month_field(field, operator, value)
          helpdesk_spent_time_filter_sql(field, operator, value, 'current_month')
        end

        def sql_for_spent_time_last_month_field(field, operator, value)
          helpdesk_spent_time_filter_sql(field, operator, value, 'last_month')
        end

      end
    end

    module InstanceMethods

      def initialize_available_filters_with_easy_helpdesk
        initialize_available_filters_without_easy_helpdesk

        group = l(:easy_helpdesk_name)

        add_available_filter('easy_helpdesk_maintained', {:type => :boolean, :order => 1, :group => group, :name => l(:field_is_under_helpdesk)})
        add_available_filter('aggregated_hours', {:type => :boolean, :order => 3, :group => group})
        add_available_filter('aggregated_hours_remaining', {:type => :float, :order => 4, :group => group, :label => :label_easy_helpdesk_actual_budget})
        add_available_filter('spent_time_current_month', {:type => :boolean, :order => 5, :group => group, :label => :label_filter_show_spent_time_current_month_equal_to_zero})
        add_available_filter('spent_time_last_month', {:type => :boolean, :order => 6, :group => group, :label => :label_filter_show_spent_time_last_month_equal_to_zero})
      end

      def initialize_available_columns_with_easy_helpdesk
        initialize_available_columns_without_easy_helpdesk

        group = l(:easy_helpdesk_name)

        add_available_column EasyQueryColumn.new(:'easy_helpdesk_project.monthly_hours', :caption => :field_monthly_hours, :numeric => true, :group => group, :preload => [:easy_helpdesk_project])
        add_available_column EasyQueryColumn.new(:'easy_helpdesk_project.spent_time_last_month', :caption => :field_easy_helpdesk_project_spent_time_last_month, :numeric => true, :group => group, :preload => [:easy_helpdesk_project])
        add_available_column EasyQueryColumn.new(:'easy_helpdesk_project.spent_time_current_month', :caption => :field_easy_helpdesk_project_spent_time_current_month, :numeric => true, :group => group, :preload => [:easy_helpdesk_project])
        add_available_column EasyQueryColumn.new(:'easy_helpdesk_project.aggregated_hours', :caption => :field_aggregated_hours, :group => group, :preload => [:easy_helpdesk_project])
        add_available_column EasyQueryColumn.new(:'easy_helpdesk_project.aggregated_hours_remaining', :caption => :label_easy_helpdesk_actual_budget, :numeric => true, :group => group, :preload => [:easy_helpdesk_project])
        add_available_column EasyQueryColumn.new(:'easy_helpdesk_project.aggregated_from_last_period', :caption => :label_easy_helpdesk_aggregated_from_last_period, :numeric => true, :group => group, :preload => [:easy_helpdesk_project])
        add_available_column EasyQueryColumn.new(:'easy_helpdesk_project.remaining_hours', :caption => :field_aggregated_hours_remaining, :numeric => true, :group => group, :preload => [:easy_helpdesk_project])
        add_available_column EasyQueryColumn.new(:'easy_helpdesk_project.easy_helpdesk_total_spent_time', :caption => :field_easy_helpdesk_project_spent_time_total, :sumable => :bottom, :sumable_sql => helpdesk_spent_time_sum_sql('all'), :group => group, :preload => [:easy_helpdesk_project])
      end
    end

    module ClassMethods
    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'EasyProjectQuery', 'EasyHelpdesk::EasyProjectQueryPatch'
