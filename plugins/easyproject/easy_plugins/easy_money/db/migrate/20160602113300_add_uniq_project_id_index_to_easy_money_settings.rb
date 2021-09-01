class AddUniqProjectIdIndexToEasyMoneySettings < ActiveRecord::Migration[4.2]
  def up
    if index_exists?(:easy_money_settings, [:name, :project_id], :name => 'idx_settings_nameprojectid')
      remove_index :easy_money_settings, :name => 'idx_settings_nameprojectid'
    end
    add_easy_uniq_index :easy_money_settings, [:name, :project_id], :name => 'idx_settings_nameprojectid'
  end

  def down
  end
end