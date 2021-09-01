class AddPositionToEasyHelpdeskProjectSlas < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_helpdesk_project_slas, :position, :integer, { :null => true, :default => 0 }
    EasyHelpdeskProjectSla.reset_column_information
  end

  def self.down
    remove_column :easy_helpdesk_project_slas, :position
    EasyHelpdeskProjectSla.reset_column_information
  end
end