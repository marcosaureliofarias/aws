class AddInternalNameIndexes < ActiveRecord::Migration[4.2]
  def up
    add_index :enumerations, [:internal_name], :unique => true
    add_index :trackers, [:internal_name], :unique => true
    add_index :custom_fields, [:internal_name], :unique => true
  end

  def down
  end
end
