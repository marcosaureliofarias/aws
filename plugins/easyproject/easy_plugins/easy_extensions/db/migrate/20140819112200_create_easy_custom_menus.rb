class CreateEasyCustomMenus < ActiveRecord::Migration[4.2]

  def up
    create_table :easy_custom_menus do |t|
      t.string :name, :null => false
      t.string :url, :null => false
      t.references :easy_user_type, :null => false
    end
    add_index :easy_custom_menus, :easy_user_type_id
  end

  def down
    drop_table :easy_custom_menus
  end

end
