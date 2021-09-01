class AddColumnSettingsToEasyEntityActions < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_entity_actions, :settings, :text
  end

  def down
    remove_column :easy_entity_actions, :settings
  end
end
