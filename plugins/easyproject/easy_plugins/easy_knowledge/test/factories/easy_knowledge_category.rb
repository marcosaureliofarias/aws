FactoryBot.define do
  factory :easy_knowledge_category do
    sequence(:name) { |n| "Knowledge category ##{n}" }
    association :author, :factory => :user, :firstname => 'Author'
  end
end
