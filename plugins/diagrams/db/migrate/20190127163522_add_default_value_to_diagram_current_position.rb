class AddDefaultValueToDiagramCurrentPosition < ActiveRecord::Migration[5.2]
  def up
    change_column :diagrams, :current_position, :integer, default: 1
  end

  def down
    change_column :diagrams, :current_position, :integer, default: nil
  end
end