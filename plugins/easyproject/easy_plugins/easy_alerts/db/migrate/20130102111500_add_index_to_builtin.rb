class AddIndexToBuiltin < ActiveRecord::Migration[4.2]

  def self.up
    add_index :easy_alerts, :builtin
  end

  def self.down
  end
  
end