class ByeByeAlertsAgain < ActiveRecord::Migration[4.2]

  def self.up
    Alert.delete_all
    AlertReport.delete_all
    AlertRule.delete_all
  end

  def self.down
  end
end