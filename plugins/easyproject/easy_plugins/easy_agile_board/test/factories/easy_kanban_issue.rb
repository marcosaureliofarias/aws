FactoryGirl.define do
  factory :easy_kanban_issue do
    issue
    project
    phase { '-1' }
    position { nil }
  end
end
