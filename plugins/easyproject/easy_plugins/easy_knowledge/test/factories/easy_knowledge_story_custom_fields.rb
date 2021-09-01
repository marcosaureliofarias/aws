FactoryBot.define do
  factory :easy_knowledge_story_cf, :parent => :custom_field, :class => 'EasyKnowledgeStoryCustomField' do
    sequence(:name) { |n| "Easy Knowledge Story CF ##{n}" }
    is_for_all { true }
  end
end
