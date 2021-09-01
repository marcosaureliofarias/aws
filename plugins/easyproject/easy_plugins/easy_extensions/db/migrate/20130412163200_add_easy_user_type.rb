class AddEasyUserType < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :easy_user_type, :integer, { :null => false, :default => 1 }
  end

  def self.down
    remove_column :users, :easy_user_type
  end

end