class AddIsClosedIsWonIsPaidToEasyCrmCaseStatuses < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_crm_case_statuses, :is_closed, :boolean, :default => false
    add_column :easy_crm_case_statuses, :is_won, :boolean, :default => false
    add_column :easy_crm_case_statuses, :is_paid, :boolean, :default => false
  end
end
