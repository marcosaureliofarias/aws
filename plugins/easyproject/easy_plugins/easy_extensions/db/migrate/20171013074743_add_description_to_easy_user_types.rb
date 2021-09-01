class AddDescriptionToEasyUserTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_user_types, :description, :text, { null: true }
  end
end
