FactoryBot.define do

  factory :easy_currency_exchange_rate do
    base_code { 'CZK' }
    to_code { 'EUR' }
    rate { rand(1..100) }
    valid_on { nil }
  end

end