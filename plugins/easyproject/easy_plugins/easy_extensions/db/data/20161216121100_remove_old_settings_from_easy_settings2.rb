class RemoveOldSettingsFromEasySettings2 < EasyExtensions::EasyDataMigration
  def self.up
    EasySetting.where(:name => [
        'user_list_default_columns',
        'project_list_default_columns',
        'issue_default_sorting_array',
        'issue_default_sorting_string_short',
        'issue_default_sorting_string_long',
        'easy_issue_query_default_sorting_string_short',
        'easy_issue_query_default_sorting_string_long'
    ]).destroy_all
  end

  def self.down
  end
end
