FactoryBot.define do
  factory :re_setting do
    association :project, factory: :project

    name  { 'Name' }
    value { 'Value' }
  end
end