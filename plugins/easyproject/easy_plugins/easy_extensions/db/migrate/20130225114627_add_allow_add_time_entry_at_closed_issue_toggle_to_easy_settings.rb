class AddAllowAddTimeEntryAtClosedIssueToggleToEasySettings < ActiveRecord::Migration[4.2]
  def up
    EasySetting.create(:name => 'allow_log_time_to_closed_issue', :value => true)
  end

  def down
    EasySetting.where(:name => 'allow_log_time_to_closed_issue').destroy_all
  end

end
