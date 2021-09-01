class CreateEasyBroadcasts < ActiveRecord::Migration[4.2]
  def up

    if !table_exists? :easy_broadcasts
      create_table :easy_broadcasts do |t|
        t.text :message, null: false
        t.datetime :start_at, null: false, index: true
        t.datetime :end_at, null: false, index: true
        t.belongs_to :author

        t.timestamps null: false
      end
    end

    if !table_exists? :easy_broadcasts_user_types
      create_table :easy_broadcasts_user_types, primary_key: %i[easy_broadcast_id easy_user_type_id] do |t|
        t.belongs_to :easy_broadcast
        t.belongs_to :easy_user_type
      end
    end

  end

  def down
    drop_table :easy_broadcasts_user_types
    drop_table :easy_broadcasts
  end

end