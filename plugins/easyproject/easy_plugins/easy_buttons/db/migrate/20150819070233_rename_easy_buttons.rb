class RenameEasyButtons < ActiveRecord::Migration[4.2]
  def up
    rename_table :easy_action_buttons, :easy_buttons
  end

  def down
    rename_table :easy_buttons, :easy_action_buttons
  end
end
