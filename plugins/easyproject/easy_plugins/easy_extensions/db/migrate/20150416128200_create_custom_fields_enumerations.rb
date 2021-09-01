class CreateCustomFieldsEnumerations < ActiveRecord::Migration[5.2]
  def change
    create_table :custom_fields_enumerations, primary_key: %i[custom_field_id enumeration_id] do |t|
      t.belongs_to :custom_field
      t.belongs_to :enumeration
    end

    TimeEntryCustomField.update_all visible: true
  end

end
