FactoryBot.define do
  factory :easy_money_rate do
    association :rate_type, factory: :easy_money_rate_type
    easy_currency_code { 'CZK' }
    association :entity, factory: :user

    unit_rate { 1000 }
  end
end
