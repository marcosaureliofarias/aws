class CreateEasyDataTemplatesAssignments < ActiveRecord::Migration[4.2]
  def self.up
    create_table :easy_data_template_assignments do |t|
      t.column :easy_data_template_id, :int, { :null => false }
      t.column :entity_attribute_name, :string, { :null => false, :limit => 255}
      t.column :file_column_position, :int, { :null => false}
    end
    
  end

  def self.down
    drop_table :easy_data_template_assignments
  end
end
