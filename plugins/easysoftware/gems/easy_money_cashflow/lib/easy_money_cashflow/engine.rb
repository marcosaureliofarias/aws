require 'rys'

module EasyMoneyCashflow
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions
  
    rys_id 'easy_money_cashflow'
  
    initializer 'easy_money_cashflow.setup' do
      EasySetting.map do
        key :easy_money_cash_flow_query_period_date_period do
          default 90
          from_params proc { |value| value.to_i }
        end
        key :easy_money_cash_flow_query_period_date_period_type do
          default 1
          from_params proc { |value| value.to_i}
        end
      end
    end
  end
end
