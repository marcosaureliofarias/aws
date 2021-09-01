class AddCalculationPositionToProjects < ActiveRecord::Migration[4.2]
  def self.up
    add_column :projects, :calculation_position, :integer
  end

  def self.down
    remove_column :projects, :calculation_position
  end
end
