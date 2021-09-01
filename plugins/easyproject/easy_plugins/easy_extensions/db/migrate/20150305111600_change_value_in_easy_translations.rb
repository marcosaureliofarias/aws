class ChangeValueInEasyTranslations < ActiveRecord::Migration[4.2]
  def self.up
    adapter_name = EasyTranslation.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      change_column :easy_translations, :value, :text, { :null => true, :limit => 4294967295 }
    else
      change_column :easy_translations, :value, :text, { :null => true }
    end
  end

  def self.down
    # change_column :easy_translations, :value, :string, {:null => true}
  end
end
