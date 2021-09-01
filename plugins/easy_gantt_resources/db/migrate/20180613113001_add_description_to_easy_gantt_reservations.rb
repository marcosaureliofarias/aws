class AddDescriptionToEasyGanttReservations < ActiveRecord::Migration[4.2]

  def change
    add_column :easy_gantt_reservations, :description, :text
  end

end
