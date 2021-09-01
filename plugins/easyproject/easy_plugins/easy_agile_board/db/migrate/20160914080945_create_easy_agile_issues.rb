class CreateEasyAgileIssues < ActiveRecord::Migration[4.2]
  def change
    create_table :easy_kanban_issues do |t|
      t.references :project, index: true
      t.references :issue, index: true
      t.integer :phase, default: -1
      t.integer :position

      t.timestamps null: false
    end
  end
end
