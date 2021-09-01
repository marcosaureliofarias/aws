FactoryBot.define do

  factory :role do
    sequence(:name) { |n| "Role #{n}" }
    issues_visibility { "default" }
    users_visibility { "all" }

    trait :bultin do
      builtin { true }
    end

    trait :manager do
      name { "Manager"}
      issues_visibility { "all" }
      permissions do
        %i[
          add_project
          edit_project
          view_issues
          add_issues
          edit_issues
        ]
      end

    end

  end
end