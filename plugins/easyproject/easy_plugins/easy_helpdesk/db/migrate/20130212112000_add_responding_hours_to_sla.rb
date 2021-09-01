class AddRespondingHoursToSla < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_helpdesk_project_slas, :hours_to_response, :integer, {:null => false, :default => 0}
  end

  def self.down
    remove_column :easy_helpdesk_project_slas, :hours_to_response
  end
end