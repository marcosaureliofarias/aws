class ChangeDefaultEasyCrmCaseItemPosition < ActiveRecord::Migration[4.2]
  def up
    change_column_default(:easy_crm_case_items, :position, nil)
  end

  def down
    change_column_default(:easy_crm_case_items, :position, 1)
  end
end
