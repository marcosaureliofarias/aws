class MigrateUserAlerts < ActiveRecord::Migration[4.2]

  def self.up
    Alert.where(:is_for_all => false).each do |alert|
      alert.users << alert.author
    end
  end

  def self.down
  end
end