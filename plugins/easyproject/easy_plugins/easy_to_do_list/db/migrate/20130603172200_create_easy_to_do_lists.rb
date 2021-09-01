class CreateEasyToDoLists < ActiveRecord::Migration[4.2]
  def self.up
    
    create_table :easy_to_do_lists do |t|
      t.column :name, :string, {:null => false, :limit => 255}
      t.column :user_id, :integer, {:null => false}
      t.column :position, :integer, {:null => true, :default => 1}
      t.timestamps
    end

  end

  def self.down
    drop_table :easy_to_do_lists
  end
end