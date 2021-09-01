class AddIdToEasyEntityAssignments < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_entity_assignments, :id, :primary_key unless column_exists? :easy_entity_assignments, :id
  end
end
