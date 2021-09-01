class CreateDiagramVersions < ActiveRecord::Migration[4.2]
  def change
    create_table :diagram_versions do |t|
      t.belongs_to :diagram
      t.text :xml
      t.string :attachment
      t.integer :position
      t.timestamps null: false
    end
  end
end