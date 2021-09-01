class ChangeIndexEasyResourceAvOnEasyPrmu < ActiveRecord::Migration[4.2]
  def self.up

    ActiveRecord::Base.connection.indexes('easy_resource_availabilities').each do |index|
      remove_index 'easy_resource_availabilities', :name => index.name
    end

    add_index :easy_resource_availabilities, [:easy_page_zone_module_uuid], :name => 'idx_era_easy_page_zone_module_uuid'
    add_index :easy_resource_availabilities, [:author_id], :name => 'idx_era_author_id'
  end

  def self.down
  end
end
