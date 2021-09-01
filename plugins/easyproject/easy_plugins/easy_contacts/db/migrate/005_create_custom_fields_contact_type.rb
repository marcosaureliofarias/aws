class CreateCustomFieldsContactType < ActiveRecord::Migration[4.2]

  def change
    create_table :custom_fields_easy_contact_type, primary_key: %i[custom_field_id easy_contact_type_id] do |t|
      t.belongs_to :custom_field, index: { name: "idx_cfect_custom_field_id" }
      t.belongs_to :easy_contact_type, index: { name: "idx_cfect_easy_contact_type_id" }
    end
  end

end
