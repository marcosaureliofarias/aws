class AddExternalLookupOptionToEntityImportAssignment < ActiveRecord::Migration[5.2]
  def change
    change_table :easy_entity_import_attributes_assignments do |t|
      t.boolean :allow_find_by_external_id, default: false, null: false
    end
  end
end
