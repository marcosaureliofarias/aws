class AddIndexSpentOnToTimeEntries < ActiveRecord::Migration[4.2]
  def change
    add_index :time_entries, :spent_on, name: 'index_time_entries_on_spent_on'
  end
end
