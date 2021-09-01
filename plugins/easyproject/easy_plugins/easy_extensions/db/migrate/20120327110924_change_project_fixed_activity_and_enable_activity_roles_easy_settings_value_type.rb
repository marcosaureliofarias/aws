class ChangeProjectFixedActivityAndEnableActivityRolesEasySettingsValueType < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.where(["#{EasySetting.table_name}.name = ? OR #{EasySetting.table_name}.name = ?", 'project_fixed_activity', 'enable_activity_roles']).each do |e|
      e.value = e.value.to_boolean
      e.save
    end
  end

  def self.down
  end
end
