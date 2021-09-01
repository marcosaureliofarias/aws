class AddIndexOnEasyEntityActionHistories < ActiveRecord::Migration[4.2]
  def up
    add_index :easy_entity_action_histories, :easy_entity_action_id, name: :index_eea_action_id
    add_index :easy_entity_action_histories, [:entity_id, :entity_type], name: :index_eea_entity_id_and_type
  end

  def down
    remove_index :easy_entity_action_histories, name: :index_eea_action_id
    remove_index :easy_entity_action_histories, name: :index_eea_entity_id_and_type
  end
end
