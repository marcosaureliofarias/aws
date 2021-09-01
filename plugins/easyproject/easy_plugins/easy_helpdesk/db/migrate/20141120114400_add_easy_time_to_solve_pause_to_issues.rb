class AddEasyTimeToSolvePauseToIssues < ActiveRecord::Migration[4.2]

  def self.up
    add_column :issues, :easy_time_to_solve_paused_at, :datetime
  end

  def self.down
    remove_column :issues, :easy_time_to_solve_paused_at
  end

end
