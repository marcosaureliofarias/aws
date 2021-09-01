class AddDefaultToHelpdeskProjects < ActiveRecord::Migration[4.2]

  def self.up

    add_column :easy_helpdesk_projects, :is_default, :boolean, {:null => true}

  end

  def self.down
  end
end