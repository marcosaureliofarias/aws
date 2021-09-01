class AddEasyQueryRoles < ActiveRecord::Migration[5.2]
  def change
    create_table :easy_queries_roles, primary_key: %i[easy_query_id role_id] do |t|
      t.belongs_to :easy_query
      t.belongs_to :role
    end
  end
end
