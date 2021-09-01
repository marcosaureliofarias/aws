FactoryBot.define do
  factory :easy_knowledge_story do
    sequence(:name) { |n| "Knowledge story ##{n}" }
    association :author, :factory => :user, :firstname => 'Author'
  end
end
