class EasyContactsReferences < ActiveRecord::Migration[5.2]
  def change
    create_table :easy_contacts_references, primary_key: %i[referenced_by referenced_to] do |t|
      t.integer :referenced_by, null: false
      t.integer :referenced_to, null: false
    end
  end

end
