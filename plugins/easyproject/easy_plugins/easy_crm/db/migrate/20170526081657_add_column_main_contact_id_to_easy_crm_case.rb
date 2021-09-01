class AddColumnMainContactIdToEasyCrmCase < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_crm_cases, :main_easy_contact_id, :integer, default: nil
  end
  def down
    remove_column :easy_crm_cases, :main_easy_contact_id
  end
end
