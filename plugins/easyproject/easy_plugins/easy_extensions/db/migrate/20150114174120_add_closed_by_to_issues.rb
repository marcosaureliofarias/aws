class AddClosedByToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :easy_closed_by_id, :integer, { :null => true }
  end
end
