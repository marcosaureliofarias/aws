class AddEasyIconToTracker < ActiveRecord::Migration[4.2]
  def change
    add_column :trackers, :easy_icon, :string
  end
end
