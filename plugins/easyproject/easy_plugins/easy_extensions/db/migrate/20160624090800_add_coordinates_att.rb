class AddCoordinatesAtt < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_attendances, :arrival_latitude, :float, { null: true }
    add_column :easy_attendances, :arrival_longitude, :float, { null: true }

    add_column :easy_attendances, :departure_latitude, :float, { null: true }
    add_column :easy_attendances, :departure_longitude, :float, { null: true }
  end
end
