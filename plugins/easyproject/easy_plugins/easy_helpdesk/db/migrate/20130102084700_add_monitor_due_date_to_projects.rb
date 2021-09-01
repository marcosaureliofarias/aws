class AddMonitorDueDateToProjects < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_helpdesk_projects, :monitor_due_date, :boolean, {:null => false, :default => true}
    add_column :easy_helpdesk_projects, :monitor_spent_time, :boolean, {:null => false, :default => true}
  end

  def self.down
    remove_column :easy_helpdesk_projects, :monitor_due_date
    remove_column :easy_helpdesk_projects, :monitor_spent_time
  end
end