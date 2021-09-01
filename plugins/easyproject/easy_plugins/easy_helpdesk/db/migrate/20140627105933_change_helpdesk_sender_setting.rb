require_dependency 'easy_helpdesk/internals'

class ChangeHelpdeskSenderSetting < ActiveRecord::Migration[4.2]
  def self.up
    sender = EasySetting.value('easy_helpdesk_sender_is_user')
    EasySetting.where(:name => 'easy_helpdesk_sender_is_user').destroy_all

    if sender.nil?
      sender = EasyHelpdesk.sender_setting.first
    else
      sender = sender ? 'current_user' : 'redmine_default'
    end

    EasySetting.create(:name => 'easy_helpdesk_sender', :value => sender)
  end

  def self.down
    EasySetting.where(:name => 'easy_helpdesk_sender').destroy_all
  end
end
