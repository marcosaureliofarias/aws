class AddEndTimeToEasyEntityActivities < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_entity_activities, :end_time, :datetime
  end
end