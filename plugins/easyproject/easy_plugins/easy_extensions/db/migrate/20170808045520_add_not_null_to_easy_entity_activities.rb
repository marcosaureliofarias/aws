class AddNotNullToEasyEntityActivities < ActiveRecord::Migration[4.2]
  def up
    change_column_null :easy_entity_activities, :entity_id, false
    change_column_null :easy_entity_activities, :entity_type, false

    execute 'delete from easy_entity_activities where category_id is null'
    change_column_null :easy_entity_activities, :category_id, false
  end

  def down
    change_column_null :easy_entity_activities, :entity_id, true
    change_column_null :easy_entity_activities, :entity_type, true
    change_column_null :easy_entity_activities, :category_id, true
  end
end
