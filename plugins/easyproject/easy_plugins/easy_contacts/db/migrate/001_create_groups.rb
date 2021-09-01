class CreateGroups < ActiveRecord::Migration[4.2]

  def self.up
    create_table :easy_contacts_groups do |t|
      t.column :group_name, :string, { :null => false, :length => 255 }
      t.column :author_note, :text, { :null => true }
      t.column :is_public, :boolean, { :null => false, :default => false }
      t.column :author_id, :integer, { :null => false }
      t.column :parent_id, :integer, { :null => true }
      t.column :entity_id, :integer, { :null => true }
      t.column :entity_type, :string, { :null => true, :length => 255 }
      t.column :lft, :integer, { :null => true }
      t.column :rgt, :integer, { :null => true }
      t.column :created_on, :timestamp
      t.column :updated_on, :timestamp
    end
  end

  def self.down
    drop_table :easy_contacts_groups
  end
end
