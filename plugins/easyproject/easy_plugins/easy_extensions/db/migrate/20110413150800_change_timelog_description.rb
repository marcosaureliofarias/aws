class ChangeTimelogDescription < ActiveRecord::Migration[4.2]
  def self.up
    change_column :time_entries, :comments, :text, { :null => true }
  end

  def self.down
  end
end
