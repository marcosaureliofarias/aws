FactoryBot.define do

  factory :easy_contact_custom_field, parent: :custom_field, class: 'EasyContactCustomField' do
    sequence(:name) { |n| (internal_name || "Contact CF ##{n}").humanize }
  end

  factory :easy_contact_type do
    sequence(:type_name) { |n| "ContactType ##{n}" }
    internal_name { %w(personal corporate account).sample }
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

    trait :default do
      is_default { true }
    end
  end

  factory :easy_contact do
    sequence(:firstname) { |n| "FirstName ##{n}" }
    sequence(:lastname) { |n| "LastName ##{n}" }

    easy_contact_type { EasyContactType.default || FactoryBot.create(:easy_contact_type) }


    trait :personal do
      easy_contact_type { EasyCore::Factory.foc(EasyContactType, internal_name: "personal") }
    end

    trait :corporate do
      sequence(:firstname) { |n| "Company ##{n}" }
      easy_contact_type { EasyCore::Factory.foc(EasyContactType, internal_name: "corporate") }
      lastname { nil }
    end

    trait :account do
      easy_contact_type { EasyCore::Factory.foc(EasyContactType, internal_name: "account") }

    end
  end
end if defined?(EasyContact)

