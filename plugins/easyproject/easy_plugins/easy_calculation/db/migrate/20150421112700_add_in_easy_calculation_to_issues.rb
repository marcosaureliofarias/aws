class AddInEasyCalculationToIssues < ActiveRecord::Migration[4.2]
  def up
    add_column(:issues, :in_easy_calculation, :boolean, :default => true)
  end

  def down
    remove_column(:issues, :in_easy_calculation)
  end
end
