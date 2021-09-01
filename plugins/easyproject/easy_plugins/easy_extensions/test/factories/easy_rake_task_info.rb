FactoryBot.define do
  factory :easy_rake_task_info do
    easy_rake_task { FactoryBot.create :easy_rake_task }
    status { EasyRakeTaskInfo::STATUS_PLANNED }
    started_at { Date.today }
  end
end