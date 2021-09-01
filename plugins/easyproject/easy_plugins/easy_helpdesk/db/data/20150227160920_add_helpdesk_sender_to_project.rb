class AddHelpdeskSenderToProject < EasyExtensions::EasyDataMigration
  def up
    EasySetting.create!(name: 'easy_helpdesk_allow_custom_sender', value: false)
    EasySetting.create!(name: 'easy_helpdesk_custom_sender', value: '')
  end

  def down
    EasySetting.where(name: ['easy_helpdesk_allow_custom_sender', 'easy_helpdesk_custom_sender']).destroy_all
  end
end
