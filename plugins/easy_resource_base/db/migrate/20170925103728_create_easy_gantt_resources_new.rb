class CreateEasyGanttResourcesNew < ActiveRecord::Migration[4.2]

  # Original migrations from easy_gantt_resources
  def up
    if !table_exists?(:easy_gantt_resources)
      create_easy_gantt_resources
    end

    if !column_exists?(:easy_gantt_resources, :user_id, :integer, null: true)
      change_column_null(:easy_gantt_resources, :user_id, true)
    end

    if index_exists?(:easy_gantt_resources, [:user_id, :issue_id, :date], unique: true)
      remove_index(:easy_gantt_resources, column: [:user_id, :issue_id, :date])
    end

    # Remove duplicity first
    ActiveRecord::Base.connection.execute('DELETE FROM easy_gantt_resources WHERE id NOT IN (SELECT * FROM (SELECT MAX(id) FROM easy_gantt_resources GROUP BY user_id, issue_id, date) AS r)')
  end

  def down
    drop_table :easy_gantt_resources
  end

  private

    def create_easy_gantt_resources
      create_table :easy_gantt_resources do |t|
        t.belongs_to :user, null: false, index: true
        t.belongs_to :issue, null: false, index: true

        t.date :date, null: false, index: true
        t.decimal :hours, precision: 6, scale: 1, null: false
        t.boolean :custom, default: false, null: false

        t.timestamps(null: false)
      end
    end

end
