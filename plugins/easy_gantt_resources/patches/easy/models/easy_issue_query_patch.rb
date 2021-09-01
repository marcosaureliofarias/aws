module EasyGanttResources
  module EasyIssueQueryPatch

    def self.included(base)
      base.class_eval do
        alias_method_chain :initialize_available_filters, :easy_gantt_resources
        alias_method_chain :initialize_available_columns, :easy_gantt_resources
        alias_method_chain :preloads_for_entities, :easy_gantt_resources
      end
    end

    def initialize_available_filters_with_easy_gantt_resources
      initialize_available_filters_without_easy_gantt_resources

      group = l('easy_gantt_resources_plugin_name')

      on_filter_group(group) do
        add_available_filter 'allocated_hours', type: :float,
                                                label: :label_allocated_hours

        add_available_filter 'allocated_dates', type: :date_period,
                                                label: :label_allocated_dates
      end
    end

    def initialize_available_columns_with_easy_gantt_resources
      initialize_available_columns_without_easy_gantt_resources

      group = l('easy_gantt_resources_plugin_name')

      sumable_sql = 'COALESCE(
           (SELECT SUM(egs.hours)
            FROM easy_gantt_resources egs
            WHERE egs.issue_id = issues.id), 0)'

      add_available_column :allocated_hours, caption: :label_easy_gantt_allocations,
                                             sumable: :bottom,
                                             numeric: true,
                                             sumable_sql: sumable_sql,
                                             group: group
    end

    def preloads_for_entities_with_easy_gantt_resources(issues)
      preloads_for_entities_without_easy_gantt_resources(issues)

      if has_column?(:allocated_hours)
        Issue.load_allocated_hours(issues)
      end
    end

    def sql_for_allocated_hours_field(field, operator, value)
      db_table = ''
      db_field = 'COALESCE(
           (SELECT SUM(egs.hours)
            FROM easy_gantt_resources egs
            WHERE egs.issue_id = issues.id), 0)'

      sql_for_field(field, operator, value, db_table, db_field)
    end

    def sql_for_allocated_dates_field(field, operator, value)
      condition = sql_for_field(field, operator, value, 'easy_gantt_resources', 'date')
      issue_ids = EasyGanttResource.where(condition).select('issue_id').to_sql

      Arel.sql('issues.id').in(Arel.sql(issue_ids)).to_sql
    end

  end
end

RedmineExtensions::PatchManager.register_model_patch 'EasyIssueQuery', 'EasyGanttResources::EasyIssueQueryPatch'
