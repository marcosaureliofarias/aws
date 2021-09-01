class AddEasyAlertsMailGroup < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_alerts, :mail_for, :string, {:null => false, :default => 'all'}
    add_column :easy_alerts, :mail_group_id, :integer, {:null => true}
  end

  def self.down
    remove_column :easy_alerts, :mail_for
    remove_column :easy_alerts, :mail_group_id
  end
  
end