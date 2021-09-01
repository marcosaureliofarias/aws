class RemoveTicketPrefixFromTracker < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :trackers, :easy_issue_prefix
  end

  def self.down
    add_column :trackers, :easy_issue_prefix, :string, { :null => true, :limit => 255 }
  end
end