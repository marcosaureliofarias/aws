class AddTrackerIdToEasyHelpdeskProjectSlas < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_helpdesk_project_slas, :tracker_id, :integer
    EasyHelpdeskProjectSla.reset_column_information
  end

  def self.down
    remove_column :easy_helpdesk_project_slas, :tracker_id
    EasyHelpdeskProjectSla.reset_column_information
  end
end