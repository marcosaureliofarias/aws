FactoryGirl.define do
  factory :easy_currency do
    digits_after_decimal_separator { 2 }

    name { 'Euro' }
    iso_code { 'EUR' }
    symbol { '€' }

    trait :eur do
    end

    trait :usd do
      name { 'US Dollar' }
      iso_code { 'USD' }
    end

    trait :czk do
      name { 'Czech Koruna' }
      iso_code { 'CZK' }
      symbol { 'Kč' }
    end
  end
end
