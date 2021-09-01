class AddCoordinates < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_contacts, :latitude, :float, {null: true}
    add_column :easy_contacts, :longitude, :float, {null: true}
  end
end
