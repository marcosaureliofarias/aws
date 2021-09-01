class AddRolesEasyContactVisibility < ActiveRecord::Migration[4.2]
  def self.up
    add_column :roles, :easy_contacts_visibility, :string, limit: 30, default: 'all', null: false
  end

  def self.down
    remove_column :roles, :easy_contacts_visibility
  end
end
