class AddDescriptionToEnumerations < ActiveRecord::Migration[5.2]
  def up
    add_column :enumerations, :description, :string, null: true, length: 255
  end

  def down
    remove_column :enumerations, :description
  end
end
