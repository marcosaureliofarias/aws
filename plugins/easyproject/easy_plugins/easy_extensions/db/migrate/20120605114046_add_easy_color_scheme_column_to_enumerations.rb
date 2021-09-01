class AddEasyColorSchemeColumnToEnumerations < ActiveRecord::Migration[4.2]
  def change
    add_column IssuePriority.table_name, :easy_color_scheme, :string, :null => true
    add_column IssueStatus.table_name, :easy_color_scheme, :string, :null => true
    add_column Tracker.table_name, :easy_color_scheme, :string, :null => true
  end
end
