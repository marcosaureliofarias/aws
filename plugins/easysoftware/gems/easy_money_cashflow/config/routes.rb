Rails.application.routes.draw do
    # easy_money_queries
  rys_feature 'easy_money_cashflow' do
    get 'easy_money_cash_flow', to: 'easy_money_cash_flow#index', as: 'easy_money_cash_flow'
  end
end
