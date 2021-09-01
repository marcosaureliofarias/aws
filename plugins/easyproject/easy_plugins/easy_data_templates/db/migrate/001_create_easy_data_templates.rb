class CreateEasyDataTemplates < ActiveRecord::Migration[4.2]
  def self.up
    create_table :easy_data_templates do |t|
      t.column :name, :string, { :null => false, :limit => 255 }
      t.column :user_id, :int, { :null => true}
      t.column :template_type, :string, { :null => false, :limit => 50 }
      t.column :settings, :text, { :null => true }
      t.column :entity_type, :string, { :null => false, :limit => 255 }
      t.column :author_id, :int, { :null => false}
      t.column :created_on, :timestamp
      t.column :updated_on, :timestamp
    end
    
  end

  def self.down
    drop_table :easy_data_templates
  end
end
