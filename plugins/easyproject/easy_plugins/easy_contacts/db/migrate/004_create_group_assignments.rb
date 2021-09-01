class CreateGroupAssignments < ActiveRecord::Migration[4.2]

  def change
    create_table :easy_contacts_group_assignments, primary_key: %i[group_id contact_id] do |t|
      t.belongs_to :group, index: { name: "idx_ecga_easy_contact_group_id" }
      t.belongs_to :contact, index: { name: "idx_ecga_easy_contact_id" }
    end
  end

end
