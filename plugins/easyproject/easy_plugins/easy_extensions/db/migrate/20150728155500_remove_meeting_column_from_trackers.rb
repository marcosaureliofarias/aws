class RemoveMeetingColumnFromTrackers < ActiveRecord::Migration[4.2]
  def change
    remove_column :trackers, :easy_is_meeting, :boolean
  end
end
