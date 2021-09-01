class AddIsSystemToJournals < ActiveRecord::Migration[5.2]
  def change
    add_column :journals, :is_system, :boolean, default: false
  end
end
