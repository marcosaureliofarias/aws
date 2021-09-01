class AddRepositoryAttributes < ActiveRecord::Migration[4.2]

  def self.up
    add_column :repositories, :easy_username, :string, { :null => true }
    add_column :repositories, :easy_password, :string, { :null => true }
    add_column :repositories, :easy_database_url, :string, { :null => true }
  end

  def self.down
    remove_column :repositories, :easy_username
    remove_column :repositories, :easy_password
    remove_column :repositories, :easy_database_url
  end

end
