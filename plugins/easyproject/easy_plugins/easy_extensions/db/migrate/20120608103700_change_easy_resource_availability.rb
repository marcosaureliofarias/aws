class ChangeEasyResourceAvailability < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :easy_resource_availabilities, :name
  end

  def self.down
  end
end