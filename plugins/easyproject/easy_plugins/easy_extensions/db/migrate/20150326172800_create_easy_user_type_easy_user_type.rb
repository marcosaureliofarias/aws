class CreateEasyUserTypeEasyUserType < ActiveRecord::Migration[5.2]
  def change
    create_table :easy_user_types_easy_user_types, primary_key: %i[easy_user_type_id easy_user_visible_type_id] do |t|
      t.belongs_to :easy_user_type, index: { name: "idx_eut2_easy_user_type_id" }
      t.belongs_to :easy_user_visible_type, index: { name: "idx_eut2_easy_user_visible_type_id" }
    end
  end
end
