class AddRootIdColumnToEasyContactGroups < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_contacts_groups, :root_id, :integer, {:null => true}
  end

  def self.down
    remove_column :easy_contacts_groups, :root_id
  end
end
