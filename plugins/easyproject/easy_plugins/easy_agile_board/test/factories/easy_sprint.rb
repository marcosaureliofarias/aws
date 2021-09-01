FactoryGirl.define do
  factory :easy_sprint do
    transient do
      future { true }
    end
    sequence(:name) { |n| "Sprint #{n}" }
    start_date { Date.today + Random.rand(40).days - ( future ? 0 : 60) }
    due_date { start_date + 4 + Random.rand(10).days }

    association :project, add_modules: %w(easy_scrum_board easy_kanban_board)
  end
end
