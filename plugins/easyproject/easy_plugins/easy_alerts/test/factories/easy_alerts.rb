FactoryGirl.define do
  factory :alert_type do
    name { 'warning' }
    color { "#FF0000" }
  end

  factory :alert_context do
    name { 'issue' }
  end

  factory :alert do
    sequence(:name) { |n| "Alert #{n}" }
    mail_for { 'all' }
    mail { 'bubla@bubu.cc' }
    period_options { {:period => "every_day", :time => "cron", :hours => "00:00"} }

    association :type, factory: :alert_type
  end

  factory :alert_rule do
    association :context, factory: :alert_context
    name { 'easy_issue_query' }
    class_name { 'EasyAlerts::Rules::EasyIssueQuery' }
  end
end
