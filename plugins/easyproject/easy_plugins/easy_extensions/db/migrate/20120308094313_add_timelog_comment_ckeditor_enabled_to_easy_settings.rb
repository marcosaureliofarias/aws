class AddTimelogCommentCkeditorEnabledToEasySettings < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create(:name => 'timelog_comment_editor_enabled', :value => false)
  end

  def self.down
    EasySetting.where(:name => 'timelog_comment_editor_enabled').destroy_all
  end
end
