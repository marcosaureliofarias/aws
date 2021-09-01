class AddEasyMoneyTravelEntitiesSettings < ActiveRecord::Migration[4.2]
  def self.up
    EasyMoneyRate.reset_column_information
    EasyMoneySettings.create :name => 'use_travel_costs', :project_id => nil, :value => '0'
    EasyMoneySettings.create :name => 'use_travel_expenses', :project_id => nil, :value => '0'
    EasyMoneySettings.create :name => 'travel_cost_price_per_unit', :project_id => nil, :value => '0'
    EasyMoneySettings.create :name => 'travel_expense_price_per_day', :project_id => nil, :value => '0'
    EasyMoneySettings.create :name => 'travel_metric_unit', :project_id => nil, :value => 'km'
   end

  def self.down
    setting_names = ['use_travel_costs', 'use_travel_expenses', 'travel_cost_price_per_unit', 'travel_expense_price_per_day', 'travel_metric_unit']
    EasyMoneySettings.where(:name => setting_names).destroy_all
  end
end
