class AddEntityToTimeEntries < ActiveRecord::Migration[4.2]
  def up

    add_column :time_entries, :entity_id, :integer, { :null => true }
    add_column :time_entries, :entity_type, :string, { :null => true, :limit => 255 }

  end

  def down

    remove_column :time_entries, :entity_id
    remove_column :time_entries, :entity_type

  end
end
