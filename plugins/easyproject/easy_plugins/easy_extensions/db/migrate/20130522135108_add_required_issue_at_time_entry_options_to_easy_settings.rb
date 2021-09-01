class AddRequiredIssueAtTimeEntryOptionsToEasySettings < ActiveRecord::Migration[4.2]
  def change
    EasySetting.create(:name => 'required_issue_id_at_time_entry', :value => false)
  end
end
