FactoryGirl.define do
  factory :easy_sla_event do
    sequence(:name) { | n | "name-#{n}"}
    association :user
    association :project
    association :issue
    association :issue_status
  end
end
