class AddPositionToAvailableZone < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_page_available_zones, :position, :integer, { :null => true, :default => 1 }
  end

  def self.down
    remove_column :easy_page_available_zones, :position
  end
end
