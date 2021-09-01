class AddNewsSpinned < ActiveRecord::Migration[4.2]
  def self.up
    add_column :news, :spinned, :boolean, { :null => false, :default => false }
  end

  def self.down
    remove_column :news, :spinned
  end
end
