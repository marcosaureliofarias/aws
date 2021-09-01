class ChangeEasyCrmCaseColumnOnItems < ActiveRecord::Migration[4.2]
  def up
    change_column(:easy_crm_case_items, :easy_crm_case_id, :integer, null: true)
  end
end
