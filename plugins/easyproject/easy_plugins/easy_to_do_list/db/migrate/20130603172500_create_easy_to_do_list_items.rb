class CreateEasyToDoListItems < ActiveRecord::Migration[4.2]
  def self.up
    
    create_table :easy_to_do_list_items do |t|
      t.column :easy_to_do_list_id, :integer, {:null => false}
      t.column :name, :string, {:null => false, :limit => 255}
      t.column :is_done, :boolean, {:null => false, :default => false}
      t.column :position, :integer, {:null => true, :default => 1}
      t.timestamps
    end

  end

  def self.down
    drop_table :easy_to_do_list_items
  end
end