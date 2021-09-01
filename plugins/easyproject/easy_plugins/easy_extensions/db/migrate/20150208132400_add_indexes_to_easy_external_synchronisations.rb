class AddIndexesToEasyExternalSynchronisations < ActiveRecord::Migration[4.2]
  def self.up
    add_index :easy_external_synchronisations, [:entity_type, :entity_id], :unique => true, :name => 'idx_easy_ext_sync_1'
    add_index :easy_external_synchronisations, :entity_id, :name => 'idx_easy_ext_sync_2'
  end

  def self.down
    remove_index :easy_external_synchronisations, :name => 'idx_easy_ext_sync_1'
    remove_index :easy_external_synchronisations, :name => 'idx_easy_ext_sync_2'
  end
end
