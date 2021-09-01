class CreateDiagrams < ActiveRecord::Migration[4.2]
  def change
    create_table :diagrams do |t|
      t.belongs_to :project
      t.string :title
      t.text :xml
      t.string :attachment
      t.integer :current_position
      t.timestamps null: false
    end
  end
end