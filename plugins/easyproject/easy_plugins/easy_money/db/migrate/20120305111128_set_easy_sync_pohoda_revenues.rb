class SetEasySyncPohodaRevenues < ActiveRecord::Migration[4.2]
  def self.up
    EasySyncMapping.create(:category => 'EasySyncPohodaRevenues', :local_name => 'pohoda_id', :remote_id => 2, :value_type => 'string')
    EasySyncMapping.create(:category => 'EasySyncPohodaRevenues', :local_name => 'name', :remote_id => 3, :value_type => 'string')
    EasySyncMapping.create(:category => 'EasySyncPohodaRevenues', :local_name => 'spent_on', :remote_id => 1, :value_type => 'date')
    EasySyncMapping.create(:category => 'EasySyncPohodaRevenues', :local_name => 'price1', :remote_id => 7, :value_type => 'decimal')
    EasySyncMapping.create(:category => 'EasySyncPohodaRevenues', :local_name => 'price2', :remote_id => 7, :value_type => 'decimal')
  end

  def self.down
    EasySyncMapping.where(:category => 'EasySyncPohodaRevenues').destroy_all
  end
end