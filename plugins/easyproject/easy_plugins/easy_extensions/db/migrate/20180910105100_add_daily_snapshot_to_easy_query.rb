class AddDailySnapshotToEasyQuery < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_queries, :daily_snapshot, :boolean, default: false
  end
end
