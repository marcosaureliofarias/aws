class CreateEntitiesWithCurrencies < ActiveRecord::Migration[4.2]
  def up
    create_table :easy_entities_with_currencies do |t|
      t.string :entity_class
      t.date :initializaed_at
      t.date :recalculated_at
      t.timestamps
    end
  end

  def down
    drop_table :easy_entities_with_currencies
  end
end
