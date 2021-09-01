class AddMilestoneToSprint < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_sprints, :version_id, :integer, {:null => true}
  end

  def down
  end
end
