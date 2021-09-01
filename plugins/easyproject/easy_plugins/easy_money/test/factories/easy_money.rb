FactoryGirl.define do

  trait :easy_money_base_model do
    transient do
      entity_type { :project }
    end

    sequence(:name) { |n| "Test money entity ##{n}" }
    sequence(:price1, 1000) {|n| n * Random.rand(200) }
    sequence(:spent_on) {|n| Date.today - n }

    association :entity, factory: :project, :enabled_module_names => ['easy_money']
  end

  factory :easy_money_expected_expense, :traits => [:easy_money_base_model], :class => 'EasyMoneyExpectedExpense' do
    sequence(:price2, 1000) {|n| n * Random.rand(200) }
    vat { 20 }
  end

  factory :easy_money_expected_revenue, :traits => [:easy_money_base_model], :class => 'EasyMoneyExpectedRevenue' do
    sequence(:price2, 1000) {|n| n * Random.rand(200) }
    vat { 20 }
  end

  factory :easy_money_other_expense, :traits => [:easy_money_base_model], :class => 'EasyMoneyOtherExpense' do
    sequence(:price2, 1000) {|n| n * Random.rand(200) }
    vat { 20 }
  end

  factory :easy_money_other_revenue, :traits => [:easy_money_base_model], :class => 'EasyMoneyOtherRevenue' do
    sequence(:price2, 1000) {|n| n * Random.rand(200) }
    vat { 20 }
  end

  factory :easy_money_travel_cost, :traits => [:easy_money_base_model], :class => 'EasyMoneyTravelCost' do
    price_per_unit { 20 }
    metric_units { 20 }
  end

  factory :easy_money_travel_expense, :traits => [:easy_money_base_model], :class => 'EasyMoneyTravelExpense' do
    price_per_day { 20 }
    sequence(:spent_on_to) {|n| Date.today - n }
    association :user, :factory => :user, :firstname => 'TravelExpenseUser'
  end

  factory :easy_money_time_entry_expense, :class => 'EasyMoneyTimeEntryExpense' do
    price { 10 }
    association :rate_type, :factory => :easy_money_rate_type
    association :time_entry, :factory => :time_entry
  end

  factory :easy_money_project_cache, :class => 'EasyMoneyProjectCache' do
    project
  end

  factory :easy_money_rate_type, :class => 'EasyMoneyRateType' do
    name { 'internal' }
    is_default { true }
    status { EasyMoneyRateType::STATUS::ACTIVE }

    trait :external do
      name { 'external' }
      is_default { false }
    end
  end

  factory :easy_money_rate_priority do
    entity_type { 'User' }
    association :rate_type, :factory => :easy_money_rate_type
  end
end
