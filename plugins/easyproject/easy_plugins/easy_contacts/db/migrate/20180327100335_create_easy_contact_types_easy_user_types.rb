class CreateEasyContactTypesEasyUserTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :easy_contact_types_easy_user_types, primary_key: %i[easy_contact_type_id easy_user_type_id] do |t|
      t.belongs_to :easy_contact_type, index: { name: "idx_contact_type_id" }
      t.belongs_to :easy_user_type, index: { name: "idx_user_type_id" }
    end
  end
end
