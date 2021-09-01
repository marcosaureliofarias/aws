class CreateAutoclosingSettings < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create(:name => 'issue_set_done_after_close', :value => false)
  end

  def self.down
    EasySetting.where(:name => 'issue_set_done_after_close').destroy_all
  end

end