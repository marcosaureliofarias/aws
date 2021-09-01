class AddShowSumRowToEasyQuery < ActiveRecord::Migration[4.2]
  def up
    add_column :easy_queries, :show_sum_row, :boolean, :default => true
  end

  def down
    remove_column :easy_queries, :show_sum_row
  end
end
