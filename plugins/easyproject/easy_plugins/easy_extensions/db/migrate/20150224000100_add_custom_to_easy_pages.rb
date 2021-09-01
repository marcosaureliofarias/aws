class AddCustomToEasyPages < ActiveRecord::Migration[4.2]
  def up

    add_column :easy_pages, :identifier, :string, { :null => true, :limit => 255 }
    add_column :easy_pages, :entity_type, :string, { :null => true, :limit => 255 }
    add_column :easy_pages, :entity_id, :integer, { :null => true }
    add_column :easy_pages, :user_id, :integer, { :null => true }
    add_column :easy_pages, :user_defined_name, :string, { :null => true, :limit => 255 }

  end

  def down
  end
end
