class AddEasySettingsNewSubprojectsUserRoleId < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create :name => 'new_subproject_user_role_id', :value => ''
  end

  def self.down
    EasySetting.where(:name => 'new_subproject_user_role_id').destroy_all
  end
end