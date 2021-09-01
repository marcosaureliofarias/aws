class AddTimeToDueDate < ActiveRecord::Migration[4.2]
  def self.up
    add_column :issues, :easy_due_date_time, :time, { :null => true }
  end

  def self.down
    remove_column :issues, :easy_due_date_time
  end
end