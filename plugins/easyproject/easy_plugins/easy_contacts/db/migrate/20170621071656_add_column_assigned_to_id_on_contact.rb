class AddColumnAssignedToIdOnContact < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_contacts, :assigned_to_id, :integer, :index => true
  end
end
