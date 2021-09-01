class CreateEasyIcalendar < ActiveRecord::Migration[4.2]
  def up
    create_table :easy_icalendars do |t|
      t.string :name, null: false
      t.string :url, null: false
      t.string :easy_color_scheme
      t.integer :visibility, default: 0

      t.datetime :synchronized_at # success synchronized
      t.datetime :last_run_at
      t.integer :status, default: 0
      t.text :message

      t.belongs_to :user, null: false, index: true
      t.timestamps null: false
    end
  end

  def down
    drop_table :easy_icalendars
  end
end
