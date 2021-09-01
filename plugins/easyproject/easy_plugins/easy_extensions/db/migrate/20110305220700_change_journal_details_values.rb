class ChangeJournalDetailsValues < ActiveRecord::Migration[4.2]
  def self.up
    change_column :journal_details, :old_value, :text, { :null => true }
    change_column :journal_details, :value, :text, { :null => true }
  end

  def self.down
  end
end
