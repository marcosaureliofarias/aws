class ChangePageModuleIdToString < ActiveRecord::Migration[4.2]
  def up
    change_column :easy_chart_baselines, :page_module_id, :string
  end

  def down
  end
end
