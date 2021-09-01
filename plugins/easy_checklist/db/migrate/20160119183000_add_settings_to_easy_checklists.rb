class AddSettingsToEasyChecklists < ActiveRecord::Migration[4.2]
  def up
    adapter_name = ActiveRecord::Base.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      add_column :easy_checklists, :settings, :text, { :null => true, :limit => 4294967295 }
    else
      add_column :easy_checklists, :settings, :text, { :null => true }
    end
  end

  def down
    remove_column :easy_checklists, :settings
  end
end
