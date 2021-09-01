class CreateHelpdeskProjectsSla < ActiveRecord::Migration[4.2]

  def self.up
    
    create_table :easy_helpdesk_project_slas do |t|
      t.column :easy_helpdesk_project_id, :integer, {:null => false}
      t.column :keyword, :string, {:null => false, :limit => 255}
      t.column :hours, :integer, {:null => false, :default => 0}
    end

  end

  def self.down
    drop_table :easy_helpdesk_project_slas
  end
end