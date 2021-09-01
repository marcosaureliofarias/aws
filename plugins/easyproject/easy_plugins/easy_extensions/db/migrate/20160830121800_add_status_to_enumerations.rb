class AddStatusToEnumerations < ActiveRecord::Migration[4.2]
  def up
    add_column :enumerations, :status, :integer, { null: true, default: nil }
  end

  def down
    remove_column :enumerations, :status
  end
end
