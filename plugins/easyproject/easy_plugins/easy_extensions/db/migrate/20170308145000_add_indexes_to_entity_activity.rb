class AddIndexesToEntityActivity < ActiveRecord::Migration[4.2]
  def self.up
    add_index :easy_entity_activities, [:entity_type, :entity_id], name: :index_eea_on_entity
    add_index :easy_entity_activities, :author_id, name: :index_eea_on_author_id
    add_index :easy_entity_activity_attendees, [:entity_type, :entity_id], name: :index_eeaa_on_entity
    add_index :easy_entity_activity_attendees, :easy_entity_activity_id, name: :index_eeaa_on_activity_id
  end

  def self.down
    remove_index :easy_entity_activities, name: :index_eea_on_entity
    remove_index :easy_entity_activities, name: :index_eea_on_author_id
    remove_index :easy_entity_activity_attendees, name: :index_eeaa_on_entity
    remove_index :easy_entity_activity_attendees, name: :index_eeaa_on_activity_id
  end
end
