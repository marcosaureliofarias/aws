class AddIsForSubprojectsToEasyQuery < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_queries, :is_for_subprojects, :boolean
  end
end
