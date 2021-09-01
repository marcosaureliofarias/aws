class AddProjectIdToEasyGanttReservations < ActiveRecord::Migration[5.2]
  def change
    add_column :easy_gantt_reservations, :project_id, :integer
  end
end
