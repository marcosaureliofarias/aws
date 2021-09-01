class CreateHelpdeskProjects < ActiveRecord::Migration[4.2]

  def self.up
    
    create_table :easy_helpdesk_projects do |t|
      t.column :project_id, :integer, {:null => false}
      t.column :tracker_id, :integer, {:null => false}
      t.column :assigned_to_id, :integer, {:null => true}
    end

    create_table :easy_helpdesk_project_matchings do |t|
      t.column :easy_helpdesk_project_id, :integer, {:null => false}
      t.column :domain_name, :string, {:null => false, :limit => 255}
    end

  end

  def self.down
    drop_table :easy_helpdesk_projects
    drop_table :easy_helpdesk_project_matchings
  end
end