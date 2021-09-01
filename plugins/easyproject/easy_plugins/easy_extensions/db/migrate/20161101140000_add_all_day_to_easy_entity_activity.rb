class AddAllDayToEasyEntityActivity < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_entity_activities, :all_day, :boolean
  end
end
