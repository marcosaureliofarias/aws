FactoryBot.define do
  factory :easy_gantt_resource do
    user_id { User.current.id }
    issue_id { 0 }
    date { Date.today }
    hours { 5 }
    custom { true }
    #start

    transient do
      issue { nil }
    end

    after :build do |resource, options|
      unless options.issue.nil?
        resource.user_id = options.issue.assigned_to_id
        resource.issue_id = options.issue.id
      end
    end
  end
end