class AddIndexStartTimeToEasyEntityActivities < ActiveRecord::Migration[4.2]
  def change
    add_index :easy_entity_activities, :start_time, name: 'idx_eea_on_start_time'
  end
end
