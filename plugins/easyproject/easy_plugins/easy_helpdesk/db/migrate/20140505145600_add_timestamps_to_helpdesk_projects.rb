class AddTimestampsToHelpdeskProjects < ActiveRecord::Migration[4.2]

  def self.up
    add_timestamps(:easy_helpdesk_projects)
  end

  def self.down
    remove_timestamps(:easy_helpdesk_projects)
  end

end