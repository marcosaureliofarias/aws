class CreateEasyEntityImportAttributesAssignments < ActiveRecord::Migration[5.2]
  def change
    return if table_exists? :easy_entity_import_attributes_assignments

    create_table :easy_entity_import_attributes_assignments do |t|
      t.belongs_to :easy_entity_import, null: false, index: false
      t.string :source_attribute, null: true
      t.string :entity_attribute, null: false
      t.boolean :is_custom, default: false, null: false
      t.string :value, null: true

      t.text :default_value, null: true

      t.timestamps
    end
    add_index(:easy_entity_import_attributes_assignments, [:source_attribute, :entity_attribute], name: 'ee_import_att_ass_source_entity')
    add_index(:easy_entity_import_attributes_assignments, [:easy_entity_import_id, :entity_attribute], name: 'ee_import_att_ass_entity_importer')
  end

  def down
    drop_table :easy_entity_import_attributes_assignments
  end
end
