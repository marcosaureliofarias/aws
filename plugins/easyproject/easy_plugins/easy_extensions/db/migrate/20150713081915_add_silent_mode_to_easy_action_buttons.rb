class AddSilentModeToEasyActionButtons < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_action_buttons, :silent_mode, :boolean, default: true
  end

  def down
    remove_column :easy_action_buttons, :silent_mode
  end
end
