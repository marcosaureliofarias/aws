class AddEasyMoneySettings < ActiveRecord::Migration[4.2]
  def self.up
    EasyMoneySettings.create :name => 'price_visibility', :project_id => nil, :value => 'price1'
    EasyMoneySettings.create :name => 'rate_type', :project_id => nil, :value => 'all'
    EasyMoneySettings.create :name => 'include_childs', :project_id => nil, :value => '1'
    EasyMoneySettings.create :name => 'expected_revenue', :project_id => nil, :value => '1'
    EasyMoneySettings.create :name => 'expected_expense', :project_id => nil, :value => '1'
    EasyMoneySettings.create :name => 'expected_hours', :project_id => nil, :value => '1'
    EasyMoneySettings.create :name => 'expected_count_price', :project_id => nil, :value => 'price1'
    EasyMoneySettings.create :name => 'expected_rate_type', :project_id => nil, :value => 'internal'
    EasyMoneySettings.create :name => 'vat', :project_id => nil, :value => '20'
  end

  def self.down
    setting_names = ['price_visibility', 'rate_type', 'include_childs', 'expected_revenue', 'expected_expense',
      'expected_hours', 'expected_count_price', 'expected_rate_type', 'vat']
    EasyMoneySettings.where(:name => setting_names).destroy_all
  end
end
