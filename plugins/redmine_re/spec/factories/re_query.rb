FactoryBot.define do
  factory :re_query do
    association :project, factory: :project

    name { 'Name' }
    description { 'Description' }
    visibility { 'is_public' }
  end
end