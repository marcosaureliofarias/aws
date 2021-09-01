class AddActiveProjectsOnlyToAlerts < ActiveRecord::Migration[4.2]

  def self.up

    add_column :easy_alerts, :active_projects_only, :boolean, { null: false, default: false }

  end

  def self.down

    remove_column :easy_alerts, :active_projects_only

  end

end