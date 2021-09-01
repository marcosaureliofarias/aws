class AddCapacityToSprint < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_sprints, :capacity, :integer, {:null => false, :default => 0}
  end

  def down
  end
end
