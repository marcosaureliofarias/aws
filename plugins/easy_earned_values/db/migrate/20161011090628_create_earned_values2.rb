class CreateEarnedValues2 < ActiveRecord::Migration[4.2]

  def up
    # drop_table(:earned_values)       if table_exists?(:earned_values)
    # drop_table(:earned_actual_data)  if table_exists?(:earned_actual_data)
    # drop_table(:earned_planned_data) if table_exists?(:earned_planned_data)

    create_table :easy_earned_values do |t|
      t.integer :project_id
      t.integer :baseline_id
      t.string :name
      t.string :type

      t.timestamps null: false
    end

    create_table :easy_earned_value_data do |t|
      t.integer :easy_earned_value_id
      t.date :date
      t.decimal :ev, precision: 6, scale: 2
      t.decimal :ac, precision: 6, scale: 2
      t.decimal :pv, precision: 6, scale: 2
    end
  end

  def down
    drop_table :easy_earned_value_data
    drop_table :easy_earned_values
  end

end
