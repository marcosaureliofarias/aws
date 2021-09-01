FactoryBot.define do

  factory :time_entry do
    hours { 1 }
    spent_on { Date.today }

    issue
    project { issue.project }
    user
    activity { project.activities.first || FactoryBot.create(:time_entry_activity, :default) }
  end

end
