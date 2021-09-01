class AddHelpdeskEasySettings < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create(:name => 'easy_helpdesk_sender_is_user', :value => true)
    EasySetting.create(:name => 'easy_helpdesk_allow_override', :value => true)
  end

  def self.down
    EasySetting.where(:name => 'easy_helpdesk_sender_is_user').destroy_all
    EasySetting.where(:name => 'easy_helpdesk_allow_override').destroy_all
  end
end
