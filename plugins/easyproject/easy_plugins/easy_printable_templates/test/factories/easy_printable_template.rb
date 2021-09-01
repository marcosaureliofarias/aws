FactoryGirl.define do
  factory :easy_printable_template do
    transient do
      number_of_easy_printable_template_pages { 1 }
    end

    sequence(:name) { |n| "Printable template ##{n}" }
    project
    association :author, :factory => :user, :firstname => 'Author'

    trait :with_easy_printable_template_pages do
      after :create do |easy_printable_template, evaluator|
        FactoryGirl.create_list :easy_printable_template_page, evaluator.number_of_easy_printable_template_pages, :easy_printable_template => easy_printable_template
      end
    end
  end

  factory :easy_printable_template_page do
    page_text { 'page text' }
  end
end
