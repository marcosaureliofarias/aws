class AddWatcherGroupsToHelpdeskProject < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_helpdesk_projects, :watcher_groups_ids, :text, {null: true}
  end

  def self.down
    remove_column :easy_helpdesk_projects, :watcher_groups_ids
  end
end
