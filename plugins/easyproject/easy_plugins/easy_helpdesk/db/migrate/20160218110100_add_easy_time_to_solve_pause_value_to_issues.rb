class AddEasyTimeToSolvePauseValueToIssues < ActiveRecord::Migration[4.2]
  def self.up
    add_column :issues, :easy_time_to_solve_pause, :float, {:null => true}
  end

  def self.down
    remove_column :issues, :easy_time_to_solve_pause
  end
end