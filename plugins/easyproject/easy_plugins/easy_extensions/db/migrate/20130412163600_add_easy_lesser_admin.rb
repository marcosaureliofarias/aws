class AddEasyLesserAdmin < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :easy_lesser_admin, :boolean, { :null => false, :default => false }
  end

  def self.down
    remove_column :users, :easy_lesser_admin
  end

end