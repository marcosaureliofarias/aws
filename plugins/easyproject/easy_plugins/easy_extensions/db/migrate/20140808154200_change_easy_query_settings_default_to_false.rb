class ChangeEasyQuerySettingsDefaultToFalse < ActiveRecord::Migration[4.2]
  def up
    change_column_default(:easy_queries, :groups_opened, false)
    change_column_default(:easy_queries, :show_sum_row, false)
  end
end
