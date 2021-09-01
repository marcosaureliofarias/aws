class CreateEasyEntityActions < ActiveRecord::Migration[4.2]
  def self.up
    create_table :easy_entity_actions, :force => true do |t|
      t.column 'type', :string, { :null => false, :limit => 255 }
      t.column 'name', :string, { :null => false, :limit => 255 }
      t.column 'action_name', :string, { :null => false, :limit => 255 }
      t.column 'active', :boolean, { :null => false, :default => true }
      t.column 'author_id', :integer, { :null => false }

      t.column 'entity_type', :string, { :limit => 255, :null => true }
      t.column 'entity_id', :integer, { :null => true }
      t.column 'project_id', :integer, { :null => true }
      t.column 'use_journal', :boolean, { :null => false, :default => false }

      t.column 'mail', :boolean, { :null => false, :default => false }
      t.column 'mail_sender', :string, { :null => true, :limit => 255 }
      t.column 'mail_cc', :string, { :null => true, :limit => 255 }
      t.column 'mail_bcc', :string, { :null => true, :limit => 255 }
      t.column 'mail_subject', :string, { :null => true, :limit => 255 }
      t.column 'mail_html_body', :text, { :null => true }

      t.column 'easy_query_settings', :text, { :null => true }
      t.column 'execute_as', :string, { :null => false }
      t.column 'execute_as_user_id', :integer, { :null => true }

      t.column 'repeatedly', :boolean, { :null => false, :default => false }
      t.column 'period_options', :text, { :null => true }

      t.column 'last_executed', :datetime, { :null => true }
      t.column 'nextrun_at', :datetime, { :null => true }

      t.timestamps
    end

    create_table :easy_entity_action_histories, :force => true do |t|
      t.column 'easy_entity_action_id', :integer, { :null => false }
      t.column 'entity_type', :string, { :limit => 255, :null => false }
      t.column 'entity_id', :integer, { :null => false }

      t.column 'text', :text, { :null => true }

      t.timestamps
    end

    EasyEntityAction.reset_column_information
    adapter_name = EasyEntityAction.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      change_column :easy_entity_actions, 'easy_query_settings', :text, { :limit => 4294967295, :default => nil }
      change_column :easy_entity_actions, 'period_options', :text, { :limit => 4294967295, :default => nil }
      change_column :easy_entity_actions, 'mail_html_body', :text, { :limit => 4294967295, :default => nil }
    end

    EasyEntityActionHistory.reset_column_information
    adapter_name = EasyEntityActionHistory.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      change_column :easy_entity_action_histories, 'text', :text, { :limit => 4294967295, :default => nil }
    end

    add_index :easy_entity_actions, [:type]
    add_index :easy_entity_actions, [:entity_type, :entity_id]

  end

  def self.down
    drop_table :easy_entity_actions
  end
end
