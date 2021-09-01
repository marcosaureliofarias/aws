class AddMonthlyHoursToHelpdeskProjects < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_helpdesk_projects, :monthly_hours, :integer, {:null => true}
  end

  def self.down
    remove_column :easy_helpdesk_projects, :monthly_hours
  end
end