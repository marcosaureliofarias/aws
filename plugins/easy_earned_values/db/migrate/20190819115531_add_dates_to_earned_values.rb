class AddDatesToEarnedValues < ActiveRecord::Migration[5.2]

  def up
    add_column :easy_earned_values, :start_date, :date
    add_column :easy_earned_values, :due_date, :date
    add_column :easy_earned_values, :actual_reloaded_at, :date

    EasyEarnedValue.reset_column_information
    EasyEarnedValue.update_all(actual_reloaded_at: (Date.today - 1))
  end

  def down
    remove_column :easy_earned_values, :start_date
    remove_column :easy_earned_values, :due_date
    remove_column :easy_earned_values, :actual_reloaded_at
  end

end
