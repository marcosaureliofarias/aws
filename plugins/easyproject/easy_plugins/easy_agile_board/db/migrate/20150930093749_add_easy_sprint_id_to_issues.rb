class AddEasySprintIdToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :easy_sprint_id, :integer, { :null => true, :default => nil }
  end
end
