class CreateEasyEntityImports < ActiveRecord::Migration[5.2]

  def change
    return if table_exists? :easy_entity_imports

    create_table :easy_entity_imports do |t|
      t.string :type, null: false
      t.string :entity_type, null: false
      t.string :name, null: false
      t.string :api_url, null: true

      t.boolean :is_automatic, default: false, null: false

      t.text :settings, null: true

      t.timestamps
    end
  end

end
