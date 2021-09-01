class AddSelfRegisteredUserToGroupToEasySettings < EasyExtensions::EasyDataMigration
  def up
    if !EasySetting.where(name: 'self_registered_user_to_group_id').first
      EasySetting.create!(name: 'self_registered_user_to_group_id')
    end
  end

  def down
    EasySetting.where(:name => 'self_registered_user_to_group_id').destroy_all
  end
end
