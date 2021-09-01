class AddTimedIssueToTrackers < ActiveRecord::Migration[4.2]
  def change
    add_column :trackers, :easy_is_meeting, :boolean
  end
end
