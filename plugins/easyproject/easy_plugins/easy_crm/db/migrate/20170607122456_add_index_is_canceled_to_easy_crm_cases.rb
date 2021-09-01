class AddIndexIsCanceledToEasyCrmCases < ActiveRecord::Migration[4.2]
  def change
    add_index :easy_crm_cases, :is_canceled
  end
end