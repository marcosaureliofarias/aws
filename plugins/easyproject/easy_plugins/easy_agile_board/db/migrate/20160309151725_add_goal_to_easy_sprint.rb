class AddGoalToEasySprint < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_sprints, :goal, :string, :default => nil
  end
end
