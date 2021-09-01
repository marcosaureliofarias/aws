class RenamePolymorficValues < ActiveRecord::Migration[4.2]
  def self.up
    EasyContactGroup.where({:entity_type => 'User'}).update_all({:entity_type => 'Principal'})
  end

  def self.down
  end
end
