class ChangeSprintGoalToLongText < ActiveRecord::Migration[4.2]
  def up
    change_column :easy_sprints, :goal, :text, {:limit => 1073741823, :default => nil}
  end

  def down
  end
end
