class AddColumnPositionToEasyCustomMenus < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_custom_menus, :position, :integer, default: nil
  end
end
