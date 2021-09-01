class AddHelpdeskEasySettings1 < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create(:name => 'easy_helpdesk_skip_ignored_emails_headers_check', :value => false)
  end

  def self.down
    EasySetting.where(:name => 'easy_helpdesk_skip_ignored_emails_headers_check').destroy_all
  end
end
