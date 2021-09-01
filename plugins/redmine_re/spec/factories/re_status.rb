FactoryBot.define do
  factory :re_status do
    association :project, factory: :project

    alias_name  { 'Alias' }
    label { 'Label' }
  end
end