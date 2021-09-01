class RenameHoursInSla < ActiveRecord::Migration[4.2]

  def self.up
    rename_column :easy_helpdesk_project_slas, :hours, :hours_to_solve
  end

  def self.down
  end
end