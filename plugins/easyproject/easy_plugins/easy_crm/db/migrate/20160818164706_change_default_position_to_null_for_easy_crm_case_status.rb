class ChangeDefaultPositionToNullForEasyCrmCaseStatus < ActiveRecord::Migration[4.2]
  def up
    change_column :easy_crm_case_statuses, :position, :integer, { :null => true, :default => nil }
  end

  def down
  end
end
