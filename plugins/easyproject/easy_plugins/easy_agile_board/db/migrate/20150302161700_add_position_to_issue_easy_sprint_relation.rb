class AddPositionToIssueEasySprintRelation < ActiveRecord::Migration[4.2]
  def change
    add_column :issue_easy_sprint_relations, :position, :integer, {:null => true, :default => 1}

    create_table :easy_agile_backlog_relations do |t|
      t.references :project
      t.references :issue
      t.integer :position

      t.timestamps
    end
    add_index :easy_agile_backlog_relations, :project_id
    add_index :easy_agile_backlog_relations, :issue_id
  end
end
