class AddShowIssueIdToEasySettings < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create(:name => 'show_issue_id', :value => false)
  end

  def self.down
    EasySetting.where(:name => 'show_issue_id').destroy_all
  end
end
