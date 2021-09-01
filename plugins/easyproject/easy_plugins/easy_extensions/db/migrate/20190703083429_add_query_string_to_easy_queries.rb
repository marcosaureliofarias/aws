class AddQueryStringToEasyQueries < ActiveRecord::Migration[5.2]

  def up
    add_column :easy_queries, :query_string, :string
  end

  def down
    remove_column :easy_queries, :query_string
  end

end
