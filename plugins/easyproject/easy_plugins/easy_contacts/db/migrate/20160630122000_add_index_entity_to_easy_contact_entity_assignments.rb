class AddIndexEntityToEasyContactEntityAssignments < ActiveRecord::Migration[4.2]
  def up
    add_index :easy_contact_entity_assignments, [:entity_type, :entity_id], :name => 'idx_ecea_entity'
  end

  def down
  end
end