class AddFormattingColumnToQuery < ActiveRecord::Migration[4.2]

  MYSQL_TEXT_LIMIT = 4294967295

  def up
    adapter_name = ActiveRecord::Base.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      add_column :easy_queries, :custom_formatting, :text, { :limit => MYSQL_TEXT_LIMIT, :default => nil }
    else
      add_column :easy_queries, :custom_formatting, :text, { :default => nil }
    end
  end

  def down
    remove_column :easy_queries, :custom_formatting
  end
end
