class AddIndexToEasyUserReadEntities < ActiveRecord::Migration[4.2]
  def self.up
    add_index :easy_user_read_entities, [:entity_type, :entity_id], :name => 'idx_easy_read_user_entities_2'
  end

  def self.down
    remove_index :easy_user_read_entities, :name => 'idx_easy_read_user_entities_2'
  end
end
