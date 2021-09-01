class DropEasyProjectAndVersionRelations < ActiveRecord::Migration[4.2]
  def self.up
    drop_table :easy_project_relations if table_exists?(:easy_project_relations)
    drop_table :easy_version_relations if table_exists?(:easy_version_relations)
  end

  def self.down
  end
end
