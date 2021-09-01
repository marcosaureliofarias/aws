class CreateEasyChartBaselines < ActiveRecord::Migration[4.2]
  def change
    create_table :easy_chart_baselines do |t|
      t.string :page_module_id
      t.string :name
      t.string :chart_type
      t.text :data
      t.text :ticks
      t.text :options

      t.timestamps null: false
    end
  end
end
