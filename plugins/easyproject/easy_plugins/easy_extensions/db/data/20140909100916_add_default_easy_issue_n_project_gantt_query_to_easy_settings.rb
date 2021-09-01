class AddDefaultEasyIssueNProjectGanttQueryToEasySettings < ActiveRecord::Migration[4.2]
  def up
    ['default_sorting_array', 'default_filters', 'list_default_columns', 'grouped_by'].each do |type|
      EasySetting.create(:name => "easy_issue_gantt_query_#{type}", :value => EasySetting.value("easy_issue_query_#{type}"))
      EasySetting.create(:name => "easy_project_gantt_query_#{type}", :value => EasySetting.value("easy_project_query_#{type}"))
    end
  end
end
