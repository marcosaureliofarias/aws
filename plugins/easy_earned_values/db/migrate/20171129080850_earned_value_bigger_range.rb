class EarnedValueBiggerRange < ActiveRecord::Migration[4.2]

  def up
    change_column(:easy_earned_value_data, :ev, :decimal, precision: 10, scale: 2)
    change_column(:easy_earned_value_data, :ac, :decimal, precision: 10, scale: 2)
    change_column(:easy_earned_value_data, :pv, :decimal, precision: 10, scale: 2)
  end

  def down
  end

end
