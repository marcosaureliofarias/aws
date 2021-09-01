class AddEasyMoneyTravelQueriesDefaults < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create(:name => 'easy_money_travel_cost_query_list_default_columns', :value => ['project', 'spent_on', 'name', 'price1'])
    EasySetting.create(:name => 'easy_money_travel_expense_query_list_default_columns', :value => ['project', 'spent_on', 'name', 'price1'])
  end

  def self.down
    EasySetting.where(:name => 'easy_money_travel_cost_query_list_default_columns').destroy_all
    EasySetting.where(:name => 'easy_money_travel_expense_query_list_default_columns').destroy_all
  end
end