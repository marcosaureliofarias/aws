class AddChartToEasyQuery < ActiveRecord::Migration[4.2]
  def up

    add_column :easy_queries, :table, :boolean, { :null => false, :default => true }
    add_column :easy_queries, :chart, :boolean, { :null => false, :default => false }
    add_column :easy_queries, :calendar, :boolean, { :null => false, :default => false }
    add_column :easy_queries, :chart_settings, :text, { :null => true }

    adapter_name = Issue.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      change_column :easy_queries, :chart_settings, :text, { :limit => 4294967295, :default => nil }
    end

  end

  def down
  end
end
