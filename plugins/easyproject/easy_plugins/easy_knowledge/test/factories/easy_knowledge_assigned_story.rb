FactoryBot.define do
  factory :easy_knowledge_assigned_story do
    association :easy_knowledge_story, :factory => :easy_knowledge_story
    association :author, :factory => :user
    association :entity, :factory => :user
  end
end
