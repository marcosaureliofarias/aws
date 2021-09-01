class AddIndexUpdatedAtToEasyCrmCases < ActiveRecord::Migration[4.2]
  def self.up
    add_index :easy_crm_cases, :updated_at, :name => 'idx_easy_crm_cases_6'
  end

  def self.down
  end
end