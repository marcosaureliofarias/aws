FactoryGirl.define do

  factory :easy_helpdesk_project, :class => 'EasyHelpdeskProject' do
    project
    easy_helpdesk_auto_issue_closers { [] }
    keyword { '' }
    tracker { project.trackers.first }
    monthly_hours { 15 }

    trait :aggregated do
      aggregated_hours { true }
      aggregated_hours_period { 'quarterly' }
      aggregated_hours_start_date { Date.civil(Date.today.year, Date.today.month, (Date.today.day < 28) ? Date.today.day : 1) }
    end

    factory :aggregated_easy_helpdesk_project, :traits => [:aggregated]
  end

  factory :easy_rake_task_compute_aggregated_hours, :class => 'EasyRakeTaskComputeAggregatedHours' do
    active { true }
    settings {}
    period { :daily }
    interval { 1 }
    builtin { 1 }
    next_run_at { Time.now.beginning_of_day }
  end

  factory :easy_rake_task_easy_helpdesk_receive_mail, class: 'EasyRakeTaskEasyHelpdeskReceiveMail' do
    active { true }
    period { 'minutes' }
    interval { '1' }
    settings {}
  end

  factory :easy_helpdesk_project_matching, :class => 'EasyHelpdeskProjectMatching' do
    easy_helpdesk_project
    domain_name { 'easy.cz' }

    trait :from do email_field { 'from' } end
    trait :to do email_field { 'to' } end

    factory :from_easy_helpdesk_project_matching, :traits => [:from]
    factory :to_easy_helpdesk_project_matching, :traits => [:to]
  end

  factory :easy_helpdesk_project_sla, :class => 'EasyHelpdeskProjectSla' do
    easy_helpdesk_project
    tracker { easy_helpdesk_project.project.trackers.first }
    association :priority, factory: :issue_priority
    keyword { '' }
    hours_to_solve { 5 }
    hours_to_response { 10 }

    trait :working_time do
      association :easy_user_working_time_calendar, factory: :easy_user_time_calendar, user: nil
      hours_mode_from { 8 }
      hours_mode_to { 17 }
      use_working_time { true }
    end

    factory :working_time_easy_helpdesk_project_sla, :traits => [:working_time]
  end

  factory :easy_helpdesk_auto_issue_closer do
    easy_helpdesk_project
    association :observe_issue_status, :factory => :issue_status
    association :done_issue_status, :factory => :issue_status
    inactive_interval { 3 }
    inactive_interval_unit { 1 }
  end

  factory :easy_helpdesk_mail_template do
    name { 'Standart reply' }
    subject { 'Task changed.' }
    issue_status
    after(:build) { |t, options| t.mailboxes << build(:easy_rake_task_easy_helpdesk_receive_mail)  }
  end
end
