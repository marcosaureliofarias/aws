class ChangeDescriptionsToLongText < ActiveRecord::Migration[4.2]
  def up
    adapter_name = ActiveRecord::Base.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      change_column :projects, :description, :text, { :limit => 4294967295 }
      change_column :news, :description, :text, { :limit => 4294967295 }
      change_column :documents, :description, :text, { :limit => 4294967295 }
    end
  end

  def down
  end
end
