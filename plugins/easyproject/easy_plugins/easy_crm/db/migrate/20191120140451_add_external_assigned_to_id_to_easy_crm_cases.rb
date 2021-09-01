class AddExternalAssignedToIdToEasyCrmCases < ActiveRecord::Migration[4.2]
  def up
    change_table :easy_crm_cases do |t|
      t.column :external_assigned_to_id, :integer, null: true
    end
    add_index :easy_crm_cases, :external_assigned_to_id, name: 'idx_cases_ext_assignee'
  end
end
