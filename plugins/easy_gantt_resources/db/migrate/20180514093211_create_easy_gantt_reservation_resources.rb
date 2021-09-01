class CreateEasyGanttReservationResources < ActiveRecord::Migration[4.2]

  def up
    create_table :easy_gantt_reservation_resources do |t|
      t.integer :easy_gantt_reservation_id
      t.date :date, null: false
      t.decimal :hours, precision: 6, scale: 1, null: false
    end
  end

  def down
    drop_table :easy_gantt_reservation_resources
  end

end
