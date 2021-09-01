class AddUserIdToEasyActionsButtons < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_action_buttons, :author_id, :integer
    add_column :easy_action_buttons, :is_private, :boolean, default: false
  end

  def down
    remove_column :easy_action_buttons, :author_id
    remove_column :easy_action_buttons, :is_private
  end
end
