class AddSlaIdToIssue < ActiveRecord::Migration[4.2]

  def self.up
    add_column :issues, :easy_helpdesk_project_sla_id, :integer, {:null => true}
  end

  def self.down
    remove_column :issues, :easy_helpdesk_project_sla_id
  end
end