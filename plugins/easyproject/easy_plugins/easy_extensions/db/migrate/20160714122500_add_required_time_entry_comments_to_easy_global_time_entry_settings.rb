class AddRequiredTimeEntryCommentsToEasyGlobalTimeEntrySettings < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_global_time_entry_settings, :required_time_entry_comments, :boolean, :null => true, :default => false
  end

  def self.down
    remove_column :easy_global_time_entry_settings, :required_time_entry_comments
  end
end