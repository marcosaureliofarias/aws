class CreateRorysEnqueuedTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :rorys_enqueued_tasks do |t|
      # t.string :uuid
      # t.integer :status
      t.datetime :start_at
      # t.datetime :started_at
      # t.datetime :ended_at
      # t.float :duration
      t.text :data
      t.string :executor
      t.text :executions

      t.timestamps null: false
    end
  end
end
