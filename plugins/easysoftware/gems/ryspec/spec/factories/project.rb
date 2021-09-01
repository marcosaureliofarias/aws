FactoryBot.define do

  factory :project do
    transient do
      number_of_issues { 0 }
      trackers { [] }
    end

    sequence(:name){ |n| "Project ##{n}" }
    sequence(:identifier){ |n| "identifier_#{n}" }

    after(:create) do |project, evaluator|
      trackers = Array.wrap(evaluator.trackers)
      trackers = Tracker.all.to_a if trackers.empty?
      trackers = [FactoryBot.create(:tracker)] if trackers.empty?
      project.trackers = trackers
      project.project_time_entry_activities = FactoryBot.create_list(:time_entry_activity, 1) if project.project_time_entry_activities.empty?

      FactoryBot.create_list :issue, evaluator.number_of_issues, project: project
    end

    factory :project_custom_field, parent: :custom_field, class: 'ProjectCustomField'
  end

end
