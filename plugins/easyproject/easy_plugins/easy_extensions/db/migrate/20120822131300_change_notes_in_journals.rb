class ChangeNotesInJournals < ActiveRecord::Migration[4.2]
  def up
    adapter_name = Journal.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      change_column :journals, :notes, :text, { :limit => 4294967295 }
    end
  end

  def down
  end
end
