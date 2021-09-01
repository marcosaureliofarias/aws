class AlterTableTimeEntriesEasyIsBillableNullTrue < ActiveRecord::Migration[4.2]
  def up
    change_column(:time_entries, :easy_is_billable, :boolean, {:null => true, :default => nil})
  end
  def down
    #change_column(:time_entries, :easy_is_billable, :boolean, {:null => false, :default => false})
  end
end
