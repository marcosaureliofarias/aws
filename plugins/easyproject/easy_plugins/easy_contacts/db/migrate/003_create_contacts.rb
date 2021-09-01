class CreateContacts < ActiveRecord::Migration[4.2]

  def self.up
    create_table :easy_contacts do |t|
      t.column :contact_name, :string, { :null => false, :length => 255 }
      t.column :author_note, :text, { :null => true }
      t.column :type_id, :integer, { :null => false }
      t.column :is_public, :boolean, { :null => false, :default => false }
      t.column :author_id, :integer, { :null => false }
      t.column :created_on, :timestamp
      t.column :updated_on, :timestamp
    end
  end

  def self.down
    drop_table :easy_contacts
  end
end
