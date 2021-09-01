class AddEasyQuerySettingsToEasySettings < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create(:name => 'easy_issue_query_default_sorting_array', :value => [['priority', 'desc'], 'due_date', 'parent'])
    if issue_columns = Setting['issue_list_default_columns']
      EasySetting.create(:name => 'easy_issue_query_list_default_columns', :value => issue_columns)
    end
    EasySetting.create(:name => 'easy_user_query_list_default_columns', :value => ['login', 'firstname', 'lastname'])
    EasySetting.create(:name => 'easy_project_query_list_default_columns', :value => ['name', 'description'])
  end

  def self.down
    EasySetting.where(:name => 'easy_issue_query_default_sorting_array').destroy_all
    EasySetting.where(:name => 'easy_issue_query_default_sorting_string_short').destroy_all
    EasySetting.where(:name => 'easy_issue_query_default_sorting_string_long').destroy_all
    EasySetting.where(:name => 'easy_issue_query_list_default_columns').destroy_all
    EasySetting.where(:name => 'easy_user_query_list_default_columns').destroy_all
    EasySetting.where(:name => 'easy_project_query_list_default_columns').destroy_all
  end
end
