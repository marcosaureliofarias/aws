class CreateContactType < ActiveRecord::Migration[4.2]

  def self.up
    create_table :easy_contact_type do |t|
      t.column :type_name, :string, { :null => false, :length => 255 }
      t.column :position, :integer, { :null => true }
      t.column :is_default, :boolean, { :default => false, :null => false }
      t.column :icon_path, :string, { :null => true, :length => 255 }
    end
  end

  def self.down
    drop_table :easy_contact_type
  end
end
