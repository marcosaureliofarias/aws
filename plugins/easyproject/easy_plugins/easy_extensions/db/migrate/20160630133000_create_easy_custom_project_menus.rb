class CreateEasyCustomProjectMenus < ActiveRecord::Migration[4.2]

  def up
    create_table :easy_custom_project_menus do |t|
      t.string :menu_item, { :null => true }
      t.string :name, { :null => true }
      t.string :url, { :null => true, :limit => 2000 }
      t.integer :position, { :null => true, :default => '1' }

      t.references :project, { :null => false }
    end

    add_column :projects, :easy_has_custom_menu, :boolean, { :null => false, :default => false }
  end

  def down
    drop_table :easy_custom_project_menus
    remove_column :projects, :easy_has_custom_menu
  end

end
