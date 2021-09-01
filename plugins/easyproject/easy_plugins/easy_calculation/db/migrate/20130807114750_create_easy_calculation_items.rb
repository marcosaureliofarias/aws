class CreateEasyCalculationItems < ActiveRecord::Migration[4.2]
  def change
    create_table :easy_calculation_items do |t|
      t.references :project, :null => false
      t.string :name
      t.decimal :hours, :precision => 30, :scale => 2
      t.decimal :rate, :precision => 30, :scale => 2
      t.decimal :calculation_position

      t.timestamps
    end
    add_index :easy_calculation_items, :project_id
  end
end
