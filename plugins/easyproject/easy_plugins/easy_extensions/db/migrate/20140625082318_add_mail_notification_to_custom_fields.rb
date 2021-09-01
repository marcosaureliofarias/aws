class AddMailNotificationToCustomFields < ActiveRecord::Migration[4.2]
  def self.up
    add_column :custom_fields, :mail_notification, :boolean, { :default => true }
  end

  def self.down
    remove_column :custom_fields, :mail_notification
  end
end
