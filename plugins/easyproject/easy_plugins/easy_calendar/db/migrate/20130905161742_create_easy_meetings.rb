class CreateEasyMeetings < ActiveRecord::Migration[4.2]
  def up
    unless ActiveRecord::Base.connection.table_exists?('easy_meetings')
      create_table :easy_meetings do |t|
        t.string :name, :null => false
        t.text :description
        t.boolean :all_day, :null => false, :default => false
        t.datetime :start_time, :null => false
        t.datetime :end_time, :null => false
        t.references :author

        t.timestamps
      end
      add_index :easy_meetings, :author_id
    end
  end

  def down
    drop_table :easy_meetings
  end
end
