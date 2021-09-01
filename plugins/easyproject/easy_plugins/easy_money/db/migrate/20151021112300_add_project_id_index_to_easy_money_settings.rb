class AddProjectIdIndexToEasyMoneySettings < ActiveRecord::Migration[4.2]
  def up
    #add_index :easy_money_settings, [:name, :project_id], :name => 'idx_settings_nameprojectid' unless index_exists?(:easy_money_settings, [:name, :project_id], :name => 'idx_settings_nameprojectid')
  end

  def down
  end
end