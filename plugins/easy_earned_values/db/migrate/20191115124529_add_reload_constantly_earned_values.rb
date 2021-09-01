class AddReloadConstantlyEarnedValues < ActiveRecord::Migration[5.2]

  def up
    add_column :easy_earned_values, :reload_constantly, :boolean, default: false
  end

  def down
    remove_column :easy_earned_values, :reload_constantly
  end

end
