class AddEasyQueryEasyUserTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :easy_queries_easy_user_types, primary_key: %i[easy_query_id easy_user_type_id] do |t|
      t.belongs_to :easy_query
      t.belongs_to :easy_user_type
    end
  end
end
