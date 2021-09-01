class AddIndexNextActionToEasyCrmCases < ActiveRecord::Migration[4.2]
  def change
    add_index :easy_crm_cases, :next_action, name: 'idx_easy_crm_cases_next_action'
  end
end