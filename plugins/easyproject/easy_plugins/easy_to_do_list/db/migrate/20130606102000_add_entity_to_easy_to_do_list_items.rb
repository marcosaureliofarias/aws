class AddEntityToEasyToDoListItems < ActiveRecord::Migration[4.2]
  def self.up
    
    add_column :easy_to_do_list_items, :entity_id, :integer, {:null => true}
    add_column :easy_to_do_list_items, :entity_type, :string, {:null => true}

  end

  def self.down

    remove_column :easy_to_do_list_items, :entity_id, :entity_type

  end
end