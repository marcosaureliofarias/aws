class AddWatchersToHelpdeskProject < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_helpdesk_projects, :watchers_ids, :text, {:null => true}
  end

  def self.down
    remove_column :easy_helpdesk_projects, :watchers_ids
  end
end