class CreateEasyAlertsUsers < ActiveRecord::Migration[4.2]

  # def self.up
  #   create_table :easy_alerts_users, :id => false do |t|
  #     t.column :alert_id, :integer, {:null => false}
  #     t.column :user_id, :integer, {:null => false}
  #   end
  #
  #   add_index :easy_alerts_users, [:alert_id, :user_id]
  #   add_index :easy_alerts_users, :alert_id
  #   add_index :easy_alerts_users, :user_id
  # end
  #
  # def self.down
  # end
end
