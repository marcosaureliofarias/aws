class AddRootIdToEasyCustomMenus < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_custom_menus, :root_id, :integer
  end
end
