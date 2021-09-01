FactoryBot.define do
  factory :easy_checklist do
    sequence(:name) { |n| "Easy checklist #{n}" }
    author { User.current }

    trait :with_easy_checklist_items do
      after :create do |easy_checklist|
        FactoryGirl.create_list :easy_checklist_item, 3, :easy_checklist => easy_checklist
      end
    end
  end

  factory :easy_checklist_template do
    sequence(:name) { |n| "Easy checklist template #{n}" }
    author { User.current }

    trait :with_easy_checklist_items do
      after :create do |easy_checklist|
        FactoryGirl.create_list :easy_checklist_item, 1, :easy_checklist => easy_checklist
      end
    end
  end

  factory :easy_checklist_item do
    association :easy_checklist
    sequence(:subject) { |n| "Easy checklist item #{n}" }
    author { User.current }
    position { EasyChecklistItem.count + 1 }
  end
end
