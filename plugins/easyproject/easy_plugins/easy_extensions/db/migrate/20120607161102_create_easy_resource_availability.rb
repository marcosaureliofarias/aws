class CreateEasyResourceAvailability < ActiveRecord::Migration[4.2]
  def self.up
    create_table :easy_resource_availabilities do |t|
      t.column :easy_page_zone_module_uuid, :string, { :null => false }
      t.column :name, :string, { :null => false }
      t.column :description, :text, { :null => true }
      t.column :author_id, :integer, { :null => false }
      t.column :date, :date, { :null => false }
      t.column :hour, :integer, { :null => false }
      t.timestamps
    end
  end

  def self.down
    drop_table :easy_resource_availabilities
  end
end
