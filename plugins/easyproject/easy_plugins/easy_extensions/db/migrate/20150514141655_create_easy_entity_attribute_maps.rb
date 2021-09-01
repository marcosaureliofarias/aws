class CreateEasyEntityAttributeMaps < ActiveRecord::Migration[4.2]
  def change
    create_table :easy_entity_attribute_maps do |t|
      t.string :entity_from_type, :null => false
      t.string :entity_from_attribute, :null => false

      t.string :entity_to_type, :null => false
      t.string :entity_to_attribute, :null => false

      t.index [:entity_from_type, :entity_from_attribute, :entity_to_type], :name => 'i_map_from_entity', :unique => true
      t.index [:entity_from_type, :entity_to_type, :entity_to_attribute], :name => 'i_map_to_entity', :unique => true

      t.timestamps :null => false
    end
  end
end
