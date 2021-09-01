class AddDeletedToEasyButtons < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_buttons, :deleted, :boolean, default: false
  end
end
