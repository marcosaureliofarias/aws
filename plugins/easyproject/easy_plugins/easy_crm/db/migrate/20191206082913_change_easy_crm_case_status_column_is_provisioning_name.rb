class ChangeEasyCrmCaseStatusColumnIsProvisioningName < ActiveRecord::Migration[5.2]
  def change
    rename_column :easy_crm_case_statuses, :is_provisioning, :is_provisioned
  end
end
