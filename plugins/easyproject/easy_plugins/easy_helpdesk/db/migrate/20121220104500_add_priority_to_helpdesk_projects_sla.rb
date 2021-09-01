class AddPriorityToHelpdeskProjectsSla < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_helpdesk_project_slas, :priority_id, :integer, {:null => true}
  end

  def self.down
    remove_column :easy_helpdesk_project_slas, :priority_id
  end
end