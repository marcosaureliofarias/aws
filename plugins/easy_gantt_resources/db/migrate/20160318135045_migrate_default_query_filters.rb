class MigrateDefaultQueryFilters < ActiveRecord::Migration[4.2]
  def up
    # Default filters
    old_filters = EasySetting.find_by_name('easy_gantt_resource_query_default_filters')
    new_filters = EasySetting.find_by_name('easy_resource_easy_query_default_filters')

    if old_filters.present? && new_filters.blank?
      EasySetting.create!(name: 'easy_resource_easy_query_default_filters', value: old_filters.value)
    end

    # Default columns
    old_columns = EasySetting.find_by_name('easy_gantt_resource_query_list_default_columns')
    new_columns = EasySetting.find_by_name('easy_resource_easy_query_list_default_columns')

    if old_columns.present? && new_columns.blank?
      EasySetting.create!(name: 'easy_resource_easy_query_list_default_columns', value: old_columns.value)
    end

    # Rename saved easy queries
    if Redmine::Plugin.installed?(:easy_extensions)
      EasyQuery.where(type: 'EasyGanttResourceQuery').update_all(type: 'EasyResourceEasyQuery')
    end
  end

  def down
  end
end
