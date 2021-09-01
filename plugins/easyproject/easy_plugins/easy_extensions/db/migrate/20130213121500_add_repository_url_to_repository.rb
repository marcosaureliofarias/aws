class AddRepositoryUrlToRepository < ActiveRecord::Migration[4.2]
  def self.up
    add_column :repositories, :easy_repository_url, :string, { :null => true }
  end

  def self.down
    remove_column :repositories, :easy_repository_url
  end
end
