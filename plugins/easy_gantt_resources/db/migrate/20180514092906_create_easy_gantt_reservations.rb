class CreateEasyGanttReservations < ActiveRecord::Migration[4.2]

  def up
    create_table :easy_gantt_reservations do |t|
      t.integer :assigned_to_id
      t.integer :author_id
      t.string :name
      t.float :estimated_hours
      t.date :start_date
      t.date :due_date
      t.string :allocator

      t.timestamps null: false
    end
  end

  def down
    drop_table :easy_gantt_reservations
  end

end
