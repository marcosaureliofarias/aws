class AddEasyTagToEasyQuery < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_queries, :is_tagged, :boolean, { :null => false, :default => false }
  end
end
