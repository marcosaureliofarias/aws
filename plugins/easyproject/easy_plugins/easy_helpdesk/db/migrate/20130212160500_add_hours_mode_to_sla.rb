class AddHoursModeToSla < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_helpdesk_project_slas, :hours_mode_from, :string, {:null => false, :default => '00:00'}
    add_column :easy_helpdesk_project_slas, :hours_mode_to, :string, {:null => false, :default => '24:00'}
  end

  def self.down
    remove_column :easy_helpdesk_project_slas, :hours_mode_from
    remove_column :easy_helpdesk_project_slas, :hours_mode_to
  end
end