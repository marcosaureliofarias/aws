class ChangeProjectName < ActiveRecord::Migration[4.2]
  def up
    change_column :projects, 'name', :string, { :null => false, :limit => 255, :default => '' }
  end

  def down
    # Irreversible, because Easy Redmine users has already too long names :/
    # change_column :projects, "name", :string, { :null => false, :limit => 30, :default => "" }
  end
end
