class AddEasySettingsTimesheetsDefaultColumns < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create :name => 'easy_timesheet_query_list_default_columns', :value => ['user', 'start_date', 'end_date']
  end

  def self.down
    EasySetting.where(:name => 'easy_timesheet_query_list_default_columns').destroy_all
  end
end