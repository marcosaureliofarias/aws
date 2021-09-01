class CreateEasyIcalendarEvent < ActiveRecord::Migration[4.2]
  def up
    create_table :easy_icalendar_events do |t|
      t.text :summary
      t.belongs_to :easy_icalendar, index: true
      t.string :uid, null: false
      t.datetime :dtstart, null: false
      t.datetime :dtend
      t.text :description
      t.string :location
      t.string :organizer
      t.string :url
      t.boolean :is_private, default: false

      t.timestamps null: false
    end
  end

  def down
    drop_table :easy_icalendar_events
  end
end