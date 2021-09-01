class AddColumnProvisioningToEasyCrmCaseStatus < ActiveRecord::Migration[5.2]
  def change
    add_column :easy_crm_case_statuses, :is_provisioning, :boolean, default: false
  end
end
