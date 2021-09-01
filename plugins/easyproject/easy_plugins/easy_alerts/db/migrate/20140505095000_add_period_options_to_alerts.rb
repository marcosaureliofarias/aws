class AddPeriodOptionsToAlerts < ActiveRecord::Migration[4.2]

  def self.up

    add_column :easy_alerts, :period_options, :text, {:null => true}

    Alert.reset_column_information

  end

  def self.down

    remove_column :easy_alerts, :period_options

  end

end