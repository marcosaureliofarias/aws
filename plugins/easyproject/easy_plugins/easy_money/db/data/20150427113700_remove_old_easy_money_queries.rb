class RemoveOldEasyMoneyQueries < ActiveRecord::Migration[4.2]
  def self.up
    EasyQuery.where(type: 'EasyMoneyQuery').delete_all
  end

  def self.down
  end
end
