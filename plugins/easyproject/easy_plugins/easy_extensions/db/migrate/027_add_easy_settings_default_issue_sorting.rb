class AddEasySettingsDefaultIssueSorting < ActiveRecord::Migration[4.2]
  def up
  end

  def down
    EasySetting.where(:name => ['issue_default_sorting_array', 'issue_default_sorting_string_short', 'issue_default_sorting_string_long']).destroy_all
  end
end
