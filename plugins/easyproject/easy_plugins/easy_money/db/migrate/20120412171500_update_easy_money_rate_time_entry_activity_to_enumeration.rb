class UpdateEasyMoneyRateTimeEntryActivityToEnumeration < ActiveRecord::Migration[4.2]
  def self.up
    EasyMoneyRate.where(:entity_type => 'TimeEntryActivity').update_all(:entity_type => 'Enumeration')
  end

  def self.down
  end
end
