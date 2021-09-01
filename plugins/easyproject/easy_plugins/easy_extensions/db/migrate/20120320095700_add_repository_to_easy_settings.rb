class AddRepositoryToEasySettings < ActiveRecord::Migration[4.2]
  def self.up
    keywords = Setting.commit_update_keywords.first

    EasySetting.create(:name => 'commit_ref_keywords', :value => Setting.commit_ref_keywords)
    EasySetting.create(:name => 'commit_fix_keywords', :value => keywords && keywords['keywords'])
    EasySetting.create(:name => 'commit_fix_status_id', :value => keywords && keywords['status_id'])
    EasySetting.create(:name => 'commit_fix_done_ratio', :value => keywords && keywords['done_ratio'])
    EasySetting.create(:name => 'commit_fix_assignee_id', :value => '')
    EasySetting.create(:name => 'commit_logtime_enabled', :value => Setting.commit_logtime_enabled == '1')
    EasySetting.create(:name => 'commit_logtime_activity_id', :value => Setting.commit_logtime_activity_id)
  end

  def self.down
    EasySetting.where(:name => 'commit_ref_keywords').destroy_all
    EasySetting.where(:name => 'commit_fix_keywords').destroy_all
    EasySetting.where(:name => 'commit_fix_status_id').destroy_all
    EasySetting.where(:name => 'commit_fix_done_ratio').destroy_all
    EasySetting.where(:name => 'commit_fix_assignee_id').destroy_all
    EasySetting.where(:name => 'commit_logtime_enabled').destroy_all
    EasySetting.where(:name => 'commit_logtime_activity_id').destroy_all
  end
end
