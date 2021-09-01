class AddEasyVersionCategoryToVersions < ActiveRecord::Migration[4.2]
  def self.up
    add_column :versions, :easy_version_category_id, :integer
  end

  def self.down
    remove_column :versions, :easy_version_category_id
  end
end
