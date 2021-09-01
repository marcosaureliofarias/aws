class AddIndexMainEasyContactIdToEasyCrmCases < ActiveRecord::Migration[4.2]
  def change
    add_index :easy_crm_cases, :main_easy_contact_id
  end
end