class AddEasyExternalIdToEasyCrmCaseItems < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_crm_case_items, :easy_external_id, :string, null: true
  end
end
