class AddLoadedToEasyEarnedValues < ActiveRecord::Migration[5.2]

  def up
    # Before that only planned was fully reloaded during first run
    # Now, both (active, planned) values are reloaded
    add_column :easy_earned_values, :data_initilized, :boolean, default: false

    if column_exists?(:easy_earned_values, :planned_loaded)
      EasyEarnedValue.reset_column_information
      EasyEarnedValue.update_all('data_initilized = planned_loaded')

      remove_column :easy_earned_values, :planned_loaded
    end
  end

  def down
    remove_column :easy_earned_values, :data_initilized
  end

end
