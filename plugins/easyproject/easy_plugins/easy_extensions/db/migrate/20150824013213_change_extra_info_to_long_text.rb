class ChangeExtraInfoToLongText < ActiveRecord::Migration[4.2]
  def up
    adapter_name = Repository.connection_config[:adapter]
    case adapter_name.downcase
    when 'mysql', 'mysql2'
      change_column :repositories, :extra_info, :text, { :limit => 4294967295, :default => nil }
    end
  end

  def down
  end
end
