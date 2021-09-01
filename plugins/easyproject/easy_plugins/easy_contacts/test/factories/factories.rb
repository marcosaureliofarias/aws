FactoryGirl.define do

  factory :easy_contact_query, :parent => :easy_query, :class => 'EasyContactQuery' do
    name { 'TestContactQuery' }
  end

  factory :easy_contact_type, :class => 'EasyContactType' do
    sequence(:type_name) { |n| "ContactType ##{n}" }
    internal_name { ['personal', 'corporate', 'account'].sample }
    is_default { true }
    sequence(:position) { |n| n }

    trait :personal do
      internal_name { 'personal' }
    end

    trait :corporate do
      internal_name { 'corporate' }
    end

    trait :account do
      internal_name { 'account' }
    end

    factory :personal_easy_contact_type, :traits => [:personal]
    factory :corporate_easy_contact_type, :traits => [:corporate]
    factory :account_easy_contact_type, :traits => [:account]
  end

  factory :easy_contact, :class => 'EasyContact' do
    sequence(:firstname) { |n| "FirstName ##{n}" }
    sequence(:lastname) { |n| "LastName ##{n}" }
    association :easy_contact_type, :factory => :easy_contact_type

    trait :personal do
      association :easy_contact_type, :factory => :personal_easy_contact_type
    end

    trait :corporate do
      sequence(:firstname) { |n| "Company ##{n}" }
      lastname { nil }
      association :easy_contact_type, :factory => :corporate_easy_contact_type
    end

    trait :account do
      association :easy_contact_type, :factory => :account_easy_contact_type
    end

    trait :with_address_from_eu do
      cf_street_value { 'Some street 3' }
      cf_city_value { 'Some city on Vltava' }
      cf_postal_code_value { '00 000' }
      list = ISO3166::Country.all.select{|x| x.in_eu?}.map{|x| x.alpha2 }
      sequence(:cf_country_value) {|n|  list[n % list.count] }
    end

    trait :with_random_address do
      sequence(:cf_street_value) {|n| "S#{n}"}
      sequence(:cf_city_value) {|n| "C#{n}"}
      sequence(:cf_postal_code_value) {|n| "1#{n}"}
      list = ISO3166::Country.all.select{|x| x.in_eu?}.map{|x| x.alpha2 }
      sequence(:cf_country_value) {|n|  list[n % list.count] }
    end

    factory :personal_easy_contact, :traits => [:personal]
    factory :corporate_easy_contact, :traits => [:corporate]
    factory :account_easy_contact, :traits => [:account]
  end

  factory :easy_contact_group do
    sequence(:group_name) { |n| "Test contact group ##{n}" }
  end

  factory :easy_contact_custom_field, :parent => :custom_field, :class => 'EasyContactCustomField' do
    sequence(:name) { |n| "Contact CF ##{n}" }
  end

end
