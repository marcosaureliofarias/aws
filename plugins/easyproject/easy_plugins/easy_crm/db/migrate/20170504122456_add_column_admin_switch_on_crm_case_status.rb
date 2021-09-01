class AddColumnAdminSwitchOnCrmCaseStatus < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_crm_case_statuses, :only_for_admin, :boolean, default: false
  end
end
