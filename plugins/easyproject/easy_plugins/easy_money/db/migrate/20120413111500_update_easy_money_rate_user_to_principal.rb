class UpdateEasyMoneyRateUserToPrincipal < ActiveRecord::Migration[4.2]
  def self.up
    EasyMoneyRate.where(:entity_type => 'User').update_all(:entity_type => 'Principal')
  end

  def self.down
  end
end
