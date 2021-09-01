FactoryBot.define do
  factory :easy_crm_case_custom_field, parent: :custom_field, class: 'EasyCrmCaseCustomField' do
    sequence(:name) { |n| "Crm Case CF ##{n}" }
    easy_crm_case_statuses do |i|
      [i.association(:easy_crm_case_status)]
    end
  end

  factory :easy_crm_case_item do
    sequence(:name) { |n| "Crm Case Item ##{n}" }
    easy_crm_case
    total_price { 10 }
    amount { 10 }
    price_per_unit { 10 }
  end

  factory :easy_crm_case_status do
    sequence(:name) { |n| "Crm Case Status ##{n}" }

    trait :default do
      is_default { true }
    end

    trait :won do
      is_won { true }
    end
  end

  factory :easy_crm_case do
    sequence(:name) { |n| "Test case ##{n}" }
    easy_crm_case_status { EasyCrmCaseStatus.default || FactoryBot.create(:easy_crm_case_status, :default) }
    project { EasyCore::Factory.foc(Project.has_module("easy_crm"), :project, name: "CRM1") { |i| i[:enabled_module_names] = ['easy_crm'] } }
    author { EasyCore::Factory.foc(User.active, :user, admin: true) }
    association :main_easy_contact, factory: :easy_contact


    trait :won do
      easy_crm_case_status { EasyCore::Factory.foc(EasyCrmCaseStatus.active, is_won: true) }
    end

    trait :with_items do
      transient do
        crm_case_item_count { 2 }
      end

      before(:create) do |easy_crm_case, evaluator|
        create_list(:easy_crm_case_item, evaluator.crm_case_item_count, easy_crm_case: easy_crm_case)
      end

    end

      # trait :with_contacts do
      #   transient do
      #     crm_case_contacts_count { 2 }
      #   end
      #
      #   after(:create) do |easy_crm_case, evaluator|
      #     easy_contacts = EasyContact.last(2).presence || create_list(:easy_contact, evaluator.crm_case_contacts_count)
      #
      #     easy_contacts.each do |easy_contact|
      #       easy_crm_case.easy_contacts << easy_contact
      #     end
      #   end
      # end

      # trait :with_custom_fields do
      #   transient do
      #     custom_fields_count { 2 }
      #   end
      #
      #   before(:create) do |easy_crm_case, evaluator|
      #     create_list(:easy_crm_case_custom_field, evaluator.custom_fields_count, easy_crm_case_statuses: [easy_crm_case.easy_crm_case_status])
      #   end
      # end

  end
end if defined?(EasyCrmCase)
