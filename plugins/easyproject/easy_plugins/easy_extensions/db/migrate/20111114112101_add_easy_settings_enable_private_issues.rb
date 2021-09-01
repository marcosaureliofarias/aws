class AddEasySettingsEnablePrivateIssues < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create :name => 'enable_private_issues', :value => '0'
  end

  def self.down
    EasySetting.where(:name => 'enable_private_issues').destroy_all
  end
end
 