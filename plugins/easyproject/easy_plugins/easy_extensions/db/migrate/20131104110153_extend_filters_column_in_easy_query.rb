class ExtendFiltersColumnInEasyQuery < ActiveRecord::Migration[4.2]
  def up
    adapter_name = EasyQuery.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      change_column :easy_queries, :filters, :text, { :limit => 4294967295, :default => nil }
    end
  end

  def down
  end
end
