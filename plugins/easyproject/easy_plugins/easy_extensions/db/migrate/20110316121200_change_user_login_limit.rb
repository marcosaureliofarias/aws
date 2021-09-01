class ChangeUserLoginLimit < ActiveRecord::Migration[4.2]
  def self.up
    change_column :users, :login, :string, { :limit => 255, :default => "", :null => false }
  end

  def self.down
  end

end
