class CreateEasyEntityActivity < ActiveRecord::Migration[4.2]
  def change
    create_table :easy_entity_activities do |t|
      t.references :entity, polymorphic: true
      t.references :author
      t.references :category
      t.boolean :is_finished, default: false
      t.text :description
      t.datetime :start_time
      t.timestamps null: false
    end

    create_table :easy_entity_activity_attendees do |t|
      t.references :easy_entity_activity
      t.references :entity, polymorphic: true
      t.timestamps null: false
    end
  end
end
