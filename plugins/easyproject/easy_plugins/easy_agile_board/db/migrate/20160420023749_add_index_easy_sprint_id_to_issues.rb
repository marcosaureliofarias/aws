class AddIndexEasySprintIdToIssues < ActiveRecord::Migration[4.2]
  def up
    add_index :issues, :easy_sprint_id
  end

  def down
  end
end
