class CreateEasyGlobalTimeEntrySettings < ActiveRecord::Migration[4.2]
  def self.up
    create_table :easy_global_time_entry_settings, force: true do |t|
      t.integer :role_id, :null => true
      t.integer :spent_on_limit_before_today, :null => true
      t.integer :spent_on_limit_before_today_edit, :null => true
      t.integer :spent_on_limit_after_today, :null => true
      t.integer :spent_on_limit_after_today_edit, :null => true
      t.boolean :timelog_comment_editor_enabled, :null => true, :default => false
      t.boolean :time_entry_spent_on_at_issue_update_enabled, :null => true, :default => false
      t.boolean :allow_log_time_to_closed_issue, :null => true, :default => false
      t.boolean :required_issue_id_at_time_entry, :null => true, :default => false
      t.boolean :show_time_entry_range_select, :null => true, :default => false
    end
  end

  def self.down
    drop_table :easy_global_time_entry_settings
  end
end