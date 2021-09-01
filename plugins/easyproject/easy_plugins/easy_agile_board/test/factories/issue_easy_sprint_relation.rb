FactoryGirl.define do
  factory :issue_easy_sprint_relation  do
    issue
    easy_sprint
    relation_type { IssueEasySprintRelation::DEFAULT_TYPE }
    relation_position { nil }
    position { nil }
  end
end
