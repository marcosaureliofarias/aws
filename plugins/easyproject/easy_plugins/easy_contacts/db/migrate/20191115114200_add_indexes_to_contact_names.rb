class AddIndexesToContactNames < ActiveRecord::Migration[4.2]
  def change
    add_index :easy_contacts, :firstname
    add_index :easy_contacts, :lastname
  end
end
