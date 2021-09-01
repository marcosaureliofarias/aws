class ChangeSlaHoursToFloat < ActiveRecord::Migration[4.2]
  def self.up
    change_column :easy_helpdesk_project_slas, :hours_to_solve, :float, {:null => false, :default => 0}
    change_column :easy_helpdesk_project_slas, :hours_to_response, :float, {:null => false, :default => 0}
  end

  def self.down
    change_column :easy_helpdesk_project_slas, :hours_to_solve, :integer, {:null => false, :default => 0}
    change_column :easy_helpdesk_project_slas, :hours_to_response, :integer, {:null => false, :default => 0}
  end
end
