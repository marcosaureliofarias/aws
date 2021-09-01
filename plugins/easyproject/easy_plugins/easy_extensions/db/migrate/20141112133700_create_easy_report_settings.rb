class CreateEasyReportSettings < ActiveRecord::Migration[4.2]
  def self.up

    create_table :easy_report_settings, :force => true do |t|
      t.column :name, :string, { :null => false, :limit => 255 }
      t.column :last_run, :datetime, { :null => true }
      t.column :settings, :text, { :null => true }
    end
    add_index :easy_report_settings, [:name], :name => 'idx_ers_1'

    adapter_name = User.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      change_column :easy_report_settings, :settings, :text, { :limit => 4294967295, :default => nil }
    end
  end

  def self.down
    drop_table :easy_report_settings
  end
end
