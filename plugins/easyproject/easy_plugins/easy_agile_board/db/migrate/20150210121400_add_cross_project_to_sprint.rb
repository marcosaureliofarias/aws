class AddCrossProjectToSprint < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_sprints, :cross_project, :boolean, {:null => false, :default => false}
  end

  def down
  end
end
