class AddFormatToEntityImportAssignment < ActiveRecord::Migration[5.2]
  def change
    change_table :easy_entity_import_attributes_assignments do |t|
      t.string :format, null: true
    end
  end
end
