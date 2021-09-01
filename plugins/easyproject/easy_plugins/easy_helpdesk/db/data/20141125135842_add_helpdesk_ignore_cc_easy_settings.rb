class AddHelpdeskIgnoreCcEasySettings < EasyExtensions::EasyDataMigration
  def self.up
    EasySetting.create(:name => 'easy_helpdesk_ignore_cc', :value => false)
  end

  def self.down
    EasySetting.where(:name => 'easy_helpdesk_ignore_cc').destroy_all
  end
end
