class ChangePropKeyLimitInJournalDetails < ActiveRecord::Migration[4.2]
  def self.up
    change_column :journal_details, :prop_key, :string, :limit => 255
  end

  def self.down
    # change_column :journal_details, :prop_key, :string, :limit => 30
  end
end
