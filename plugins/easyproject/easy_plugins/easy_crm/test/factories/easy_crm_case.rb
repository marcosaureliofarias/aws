FactoryGirl.define do

  factory :easy_crm_case_custom_field, parent: :custom_field, class: 'EasyCrmCaseCustomField' do
    sequence(:name) { |n| "Crm Case CF ##{n}" }
    easy_crm_case_statuses do |i|
      [i.association(:easy_crm_case_status)]
    end
  end

  factory :easy_crm_case_item do
    sequence(:name) { |n| "Test crm item ##{n}" }
    easy_crm_case
    total_price { 10 }
    amount { 10 }
    price_per_unit { 10 }
  end

  factory :easy_crm_case_status do
    sequence(:name) { |n| "Test crm status ##{n}" }

    trait :default do
      is_default { true }
    end

    trait :won do
      is_won { true }
    end
  end

  factory :easy_crm_case do
    sequence(:name) { |n| "Test case ##{n}" }
    association :easy_crm_case_status, factory: :easy_crm_case_status, is_default: true
    association :project, factory: :project, enabled_module_names: ['easy_crm']

    association :author, { factory: :user, firstname: 'Author' }

    trait :won do
      association :easy_crm_case_status, factory: :easy_crm_case_status, is_won: true
    end

    trait :with_items do
      transient do
        crm_case_item_count { 2 }
      end

      before(:create) do |easy_crm_case, evaluator|
        create_list(:easy_crm_case_item, evaluator.crm_case_item_count, easy_crm_case: easy_crm_case)
      end

    end

    trait :with_contacts do
      transient do
        crm_case_contacts_count { 2 }
      end

      after(:create) do |easy_crm_case, evaluator|
        easy_contacts = create_list(:easy_contact, evaluator.crm_case_contacts_count)

        easy_contacts.each do |easy_contact|
          easy_crm_case.easy_contacts << easy_contact
        end
      end
    end

    trait :with_custom_fields do
      transient do
        custom_fields_count { 2 }
      end

      before(:create) do |easy_crm_case, evaluator|
        create_list(:easy_crm_case_custom_field, evaluator.custom_fields_count, easy_crm_case_statuses: [easy_crm_case.easy_crm_case_status])
      end
    end

  end


end
