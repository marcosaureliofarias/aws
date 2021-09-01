class AddProjectDueDate < ActiveRecord::Migration[4.2]
  def self.up
    add_column :projects, :easy_due_date, :date, { :null => true }
  end

  def self.down
    remove_column :projects, :easy_due_date
  end
end
