class ChangeDescriptionInEasyCrmCases < ActiveRecord::Migration[4.2]
  def self.up
    adapter_name = EasyCrmCase.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      change_column :easy_crm_cases, :description, :text, {:null => true, :limit => 4294967295}
    end
  end

  def self.down
  end
end
