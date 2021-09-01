class CreateEasySlidingPanelsLocations < ActiveRecord::Migration[4.2]
  def up
    create_table :easy_sliding_panels_locations do |t|
      t.string :zone
      t.string :name
      t.references :user
      t.integer :position
    end
  end

  def down
    drop_table :easy_sliding_panels_locations
  end
end
