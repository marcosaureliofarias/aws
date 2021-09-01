class AddAggregatedHoursToHelpdeskProject < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_helpdesk_projects, :aggregated_hours, :boolean, {:null => false, :default => false}
    add_column :easy_helpdesk_projects, :aggregated_hours_remaining, :float, {:null => true}
    add_column :easy_helpdesk_projects, :aggregated_hours_period, :string, {:null => true}
    add_column :easy_helpdesk_projects, :aggregated_hours_start_date, :date, {:null => true}
    add_column :easy_helpdesk_projects, :aggregated_hours_last_reset, :date, {:null => true}
    add_column :easy_helpdesk_projects, :aggregated_hours_last_update, :date, {:null => true}
    EasyHelpdeskProject.reset_column_information
  end

  def self.down
    remove_column :easy_helpdesk_projects, :aggregated_hours
    remove_column :easy_helpdesk_projects, :aggregated_hours_remaining
    remove_column :easy_helpdesk_projects, :aggregated_hours_period
    remove_column :easy_helpdesk_projects, :aggregated_hours_start_date
    remove_column :easy_helpdesk_projects, :aggregated_hours_last_reset
    remove_column :easy_helpdesk_projects, :aggregated_hours_last_update
    EasyHelpdeskProject.reset_column_information
  end
end
