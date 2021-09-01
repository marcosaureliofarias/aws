class CreateEasyRooms < ActiveRecord::Migration[4.2]
  def change
    create_table :easy_rooms do |t|
      t.string :name
      t.integer :capacity

      t.timestamps
    end
  end
end
