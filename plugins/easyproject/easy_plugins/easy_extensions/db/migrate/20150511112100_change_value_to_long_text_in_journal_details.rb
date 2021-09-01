class ChangeValueToLongTextInJournalDetails < ActiveRecord::Migration[4.2]
  def self.up
    adapter_name = JournalDetail.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      change_column :journal_details, :value, :text, { :limit => 4294967295, :default => nil }
      change_column :journal_details, :old_value, :text, { :limit => 4294967295, :default => nil }
    end
  end

  def self.down
  end
end
