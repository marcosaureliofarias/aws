class CreateEasyCrmCaseCf < ActiveRecord::Migration[4.2]
  def change

    create_table :custom_fields_easy_crm_case_status, force: true, primary_key: %i[custom_field_id easy_crm_case_status_id] do |t|
      t.belongs_to :custom_field, index: { name: "idx_custom_field_id" }
      t.belongs_to :easy_crm_case_status, index: { name: "idx_easy_crm_case_status_id" }
    end

  end

end
