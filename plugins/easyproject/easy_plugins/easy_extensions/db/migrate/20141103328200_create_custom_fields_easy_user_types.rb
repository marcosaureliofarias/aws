class CreateCustomFieldsEasyUserTypes < ActiveRecord::Migration[5.2]
  def up
    create_table :custom_fields_easy_user_types, primary_key: %i[custom_field_id easy_user_type_id] do |t|
      t.belongs_to :custom_field, index: { name: "idx_cfeut_custom_field_id" }
      t.belongs_to :easy_user_type, index: { name: "idx_cfeut_easy_user_type_id" }
    end

    UserCustomField.update_all visible: true
  end

  def down
    drop_table :custom_fields_easy_user_types
  end
end
