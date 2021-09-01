class ChangePrepaidHours < ActiveRecord::Migration[4.2]

  def self.up
    change_column :easy_helpdesk_projects, :monthly_hours, :float, {:null => true}
  end

  def self.down
  end
end