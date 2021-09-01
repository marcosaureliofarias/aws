class FillNullProjectIdentifierAgain < ActiveRecord::Migration[4.2]
  def self.up
    Project.where(identifier: nil).update_all(identifier: 'id')
  end

  def self.down
  end
end
