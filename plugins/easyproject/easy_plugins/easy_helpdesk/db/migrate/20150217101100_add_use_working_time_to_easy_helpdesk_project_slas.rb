class AddUseWorkingTimeToEasyHelpdeskProjectSlas < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_helpdesk_project_slas, :use_working_time, :boolean, {:null => false, :default => false}
    EasyHelpdeskProjectSla.reset_column_information
  end

  def self.down
    remove_column :easy_helpdesk_project_slas, :use_working_time
    EasyHelpdeskProjectSla.reset_column_information
  end
end