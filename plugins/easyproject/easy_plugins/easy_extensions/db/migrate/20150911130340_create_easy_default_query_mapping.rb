class CreateEasyDefaultQueryMapping < ActiveRecord::Migration[4.2]
  def change
    create_table :easy_default_query_mappings do |t|
      t.references :role
      t.string :entity_type, null: false
      t.integer :position
      t.references :easy_query

      t.timestamps :null => false
    end

    add_index(:easy_default_query_mappings, [:entity_type, :role_id], name: 'edqm_role_type')
  end
end
