class RemovePriority < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :re_artifact_properties, "priority"
  end

  def self.down
    add_column :re_artifact_properties, "priority", :integer
  end
end
