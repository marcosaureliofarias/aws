class AddEasyContactIsRequiredToEasyCrmStatuses < ActiveRecord::Migration[4.2]
  def up
    add_column(:easy_crm_case_statuses, :is_easy_contact_required, :boolean, {:default => false})
  end

  def down
    remove_column(:easy_crm_case_statuses, :is_easy_contact_required)
  end
end
