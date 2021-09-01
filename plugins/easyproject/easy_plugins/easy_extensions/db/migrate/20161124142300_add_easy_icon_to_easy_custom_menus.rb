class AddEasyIconToEasyCustomMenus < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_custom_menus, :easy_icon, :string
  end
end
