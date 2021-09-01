class AddPeriodToEasyQuery < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_queries, :period_start_date, :date, { :null => true }
    add_column :easy_queries, :period_zoom, :string, { :null => true, :limit => 255 }
  end

  def down
    # remove_column :easy_queries, :period_start_date
    # remove_column :easy_queries, :period_zoom
  end
end
