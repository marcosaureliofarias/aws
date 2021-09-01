class AddPeriodSettingsToEasyQuery < ActiveRecord::Migration[4.2]
  def up
    remove_column :easy_queries, :period_date_period if column_exists?(:easy_queries, :period_date_period)
    remove_column :easy_queries, :period_date_period_type if column_exists?(:easy_queries, :period_date_period_type)
    remove_column :easy_queries, :period_zoom if column_exists?(:easy_queries, :period_zoom)
    remove_column :easy_queries, :period_end_date if column_exists?(:easy_queries, :period_end_date)
    remove_column :easy_queries, :period_start_date if column_exists?(:easy_queries, :period_start_date)

    add_column :easy_queries, :period_settings, :text, { :null => true }
    adapter_name = EasyQuery.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      change_column :easy_queries, :period_settings, :text, { :limit => 4294967295, :default => nil }
    end
  end

  def down
    remove_column :easy_queries, :period_settings
  end
end
