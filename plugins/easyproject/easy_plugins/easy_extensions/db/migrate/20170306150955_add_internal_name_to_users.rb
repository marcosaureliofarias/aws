class AddInternalNameToUsers < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :internal_name, :string, limit: 255, null: true
  end

  def down
    remove_column :users, :internal_name
  end
end
