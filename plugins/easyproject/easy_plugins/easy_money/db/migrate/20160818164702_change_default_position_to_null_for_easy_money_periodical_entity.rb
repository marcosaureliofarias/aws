class ChangeDefaultPositionToNullForEasyMoneyPeriodicalEntity < ActiveRecord::Migration[4.2]
  def up
    change_column :easy_money_periodical_entities, :position, :integer, { :null => true, :default => nil }
  end

  def down
  end
end
