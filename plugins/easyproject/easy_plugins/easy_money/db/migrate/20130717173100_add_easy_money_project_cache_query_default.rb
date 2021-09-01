class AddEasyMoneyProjectCacheQueryDefault < ActiveRecord::Migration[4.2]
  def self.up

    EasySetting.create(:name => 'easy_money_project_cache_query_list_default_columns', :value => ['project', 'sum_of_all_other_revenues_price_2', 'sum_of_all_other_expenses_price_2_internal', 'other_profit_price_2_internal'])

  end

  def self.down

    EasySetting.where(:name => 'easy_money_project_cache_query_list_default_columns').destroy_all

  end
end