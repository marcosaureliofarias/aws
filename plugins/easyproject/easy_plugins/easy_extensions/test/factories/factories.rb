FactoryGirl.define do
  sequence :subject do |n|
    "Test issue #{n}"
  end

  factory :project do
    transient do
      number_of_issues { 1 }
      number_of_members { 0 }
      number_of_issue_categories { 3 }
      number_of_subprojects { 2 }
      add_modules { [] }
      members { [] }
      trackers { [] }
      issue_custom_fields { nil }
      create_trackers { false }
    end
    # name 'Test project'
    sequence(:name) { |n| "Project ##{n}" }

    after(:build) do |project, evaluator|
      project.issue_custom_fields = evaluator.issue_custom_fields if evaluator.issue_custom_fields
    end

    after(:create) do |project, evaluator|
      trackers = Array.wrap(evaluator.trackers)
      trackers = Tracker.all.to_a if trackers.empty?
      trackers.concat([FactoryGirl.create(:tracker), FactoryGirl.create(:bug_tracker)]) if evaluator.create_trackers || trackers.empty?
      project.trackers                      = trackers
      project.project_time_entry_activities = [FactoryGirl.create(:time_entry_activity)] if project.project_time_entry_activities.empty?
      project.enabled_module_names          |= evaluator.add_modules
      FactoryGirl.create_list :issue, evaluator.number_of_issues, :project => project
      FactoryGirl.create_list :member, evaluator.number_of_members, :project => project, :roles => [FactoryGirl.create(:role)]
    end

    after :create do |project, evaluator|
      evaluator.members.each do |user|
        FactoryGirl.create(:member, project: project, user: user)
      end
    end

    trait :with_milestones do
      transient do
        number_of_versions { 3 }
        milestone_options { Hash.new }
      end
      after :create do |project, evaluator|
        FactoryGirl.create_list :version, evaluator.number_of_versions, evaluator.milestone_options.merge(:project => project)
      end
    end

    trait :with_subprojects do
      after :create do |project, evaluator|
        FactoryGirl.create_list :project, evaluator.number_of_subprojects, :parent => project
      end
    end

    trait :with_categories do
      after :create do |project, evaluator|
        FactoryGirl.create_list :issue_category, evaluator.number_of_issue_categories, :project => project
      end
    end

    trait :template do
      easy_is_easy_template { true }
    end
  end

  factory :version do
    transient do
      number_of_issues { 0 }
    end
    sequence(:name) { |n| "Milestone ##{n}" }
    project
    effective_date { Date.today + 6.months }

    after :create do |version, evaluator|
      unless evaluator.number_of_issues < 1
        FactoryGirl.create_list(:issue, evaluator.number_of_issues, :with_version, fixed_version: version, project: version.project)
      end
    end
  end

  # factory :project_custom_field do
  #   sequence(:name) { |n| "Project CF ##{n}" }
  #   field_format 'string'
  #   is_for_all true
  # end

  factory :role do
    sequence(:name) { |n| "Role ##{n}" }
    permissions { Role.new.setable_permissions.collect(&:name).uniq }
  end

  factory :member_role do
    role
    member { FactoryBot.create(:member, :without_roles) }
  end

  factory :member do
    project
    user
    roles { [] }

    after :build do |member, evaluator|
      if evaluator.roles.empty?
        member.member_roles << FactoryGirl.build(:member_role, member: member)
      else
        evaluator.roles.each do |role|
          member.member_roles << FactoryGirl.build(:member_role, member: member, role: role)
        end
      end
    end

    trait :without_roles do
      after :create do |member, evaluator|
        member.member_roles.clear
      end
    end
  end

  factory :tracker do
    transient do
      issue_custom_fields { nil }
    end

    sequence(:name) { |n| "Feature ##{n}" }

    default_status { IssueStatus.first || FactoryGirl.create(:issue_status) }

    after(:build) do |tracker, evaluator|
      tracker.custom_fields = evaluator.issue_custom_fields if evaluator.issue_custom_fields
    end

    trait :bug do
      sequence(:name) { |n| "Bug ##{n}" }
    end

    factory :bug_tracker, :traits => [:bug]
  end

  factory :project_activity_role do
    project
    role
    association :role_activity, :factory => :time_entry_activity
  end

  factory :enumeration do
    name { 'TestEnum' }

    trait :default do
      name { 'Default' }
      is_default { true }
    end
  end

  factory :easy_custom_field_group, parent: :enumeration, class: 'EasyCustomFieldGroup' do
    sequence(:name) { |n| "EasGroup-#{n}" }
  end

  # not an enumeration, but same behaviour
  factory :issue_status, :class => 'IssueStatus' do
    sequence(:name) { |n| "TestStatus-#{n}" }
    default_done_ratio { 100 }

    trait :closed do
      is_closed { true }
    end
  end

  factory :issue_priority, :parent => :enumeration, :class => 'IssuePriority' do
    sequence(:name) { |n| "Priority ##{n}" }
  end

  factory :issue_category do
    sequence(:name) { |n| "Issue category ##{n}" }
    project
  end

  factory :issue_relation do
    issue_from { create(:issue) }
    issue_to { create(:issue, project: issue_from.project) }
  end

  factory :issue do
    transient do
      factory_is_child { false }
      watchers { [] }
    end

    sequence(:subject) { |n| "Test issue ##{n}" }
    #estimated_hours 4

    project { FactoryGirl.create(:project, :number_of_issues => 0) }
    tracker { project.trackers.first }
    start_date { Date.today }
    due_date { Date.today + 7.days }
    status { tracker.default_status }
    priority { IssuePriority.default || FactoryGirl.create(:issue_priority, :default) }
    association :author, :factory => :user, :firstname => "Author"
    association :assigned_to, :factory => :user, :firstname => "Assignee"

    after(:create) do |issue, evaluator|
      evaluator.watchers.each do |user|
        FactoryGirl.create(:watcher, watchable: issue, user: user)
      end
    end

    trait :child_issue do
      factory_is_child { true }
    end

    trait :reccuring do
      easy_is_repeating { true }
      easy_repeat_settings { Hash['period' => 'daily', 'daily_option' => 'each', 'daily_each_x' => '1', 'endtype' => 'endless', 'create_now' => 'none'] }
    end

    trait :recurring_monthly do
      easy_is_repeating { true }
      easy_repeat_settings { Hash['period' => 'monthly', 'monthly_option' => 'xth', 'monthly_period' => '1', 'monthly_day' => (Date.today + 3.days).mday, 'endtype' => 'endless', 'create_now' => 'none'] }
    end

    trait :with_version do
      association :fixed_version, factory: :version
    end

    trait :with_journals do
      after(:create) do |issue|
        FactoryGirl.create_list(:journal, 2, issue: issue, journalized_type: 'Issue')
      end
    end

    trait :with_description do
      sequence(:description) { |n| "Description ##{n}" }
    end

    trait :with_attachment do
      after(:create) do |issue|
        FactoryGirl.create_list(:attachment, 1, container: issue)
      end
    end

    trait :with_short_url

    after :build do |issue, evaluator|
      if evaluator.factory_is_child
        issue.parent_issue_id = FactoryGirl.create(:issue, :project => issue.project).id
      end
    end
  end

  factory :journal do
    sequence(:notes) { |n| "Notes #{n}" }
  end

  factory :journal_detail do
    association :journal, factory: :journal
    property { 'attr' }
  end

  factory :time_entry_activity, :parent => :enumeration, :class => 'TimeEntryActivity' do
    sequence(:name) { |n| "Time entry activity ##{n}" }
    projects { [] }
    initialize_with { new(name: name) }
    factory :default_time_entry_activity, :traits => [:default]
  end

  factory :time_entry do
    hours { 1 }
    spent_on { Date.today - 1.month }

    issue
    project { issue.project }
    user
    activity { project.activities.first }

    trait :current do
      spent_on { Date.today }
    end

    trait :old do
      spent_on { Date.today - 7.days }
    end

    trait :future do
      spent_on { Date.today + 70.days }
    end
  end

  factory :easy_global_time_entry_setting do
    spent_on_limit_before_today { 2 }
    spent_on_limit_before_today_edit { 5 }
    spent_on_limit_after_today { 20 }
    spent_on_limit_after_today_edit { 30 }
  end

  factory :wiki do
    project
    start_page { 'Wiki' }
    status { 1 }
  end

  factory :wiki_page do
    wiki
    sequence(:title) { |n| "Page ##{n}" }
  end

  factory :attachment do
    sequence(:filename) { |n| "Attachment ##{n}" }
    association :author, :factory => :user, :firstname => 'Author'
    association :container, :factory => :issue

    trait :with_short_url do
      after(:create) do |att|
        FactoryGirl.create_list(:easy_short_url, 1, entity: att, source_url: "/attachments/#{att.id}")
      end
    end

    trait :with_short_url_external do
      after(:create) do |att|
        FactoryGirl.create_list(:easy_short_url, 1, :allow_external, entity: att, source_url: "/attachments/#{att.id}")
      end
    end
  end

  factory :attachment_version, :parent => :attachment, :class => 'AttachmentVersion' do
    attachment
    version { 1 }
  end

  factory :easy_short_url do
    source_url { 'https://example.com/attachments/1' }

    trait :valid_1day do
      valid_to { Date.today + 1.day }
    end

    trait :allow_external do
      allow_external { true }
    end
  end

  factory :easy_issue_timer do
    user
    issue
    start { DateTime.now }
  end

  factory :easy_page_zone_module do
    easy_pages_id { 1 }
    easy_page_available_zones_id { 1 }
    easy_page_available_modules_id { EpmIssueQuery.first.id }
    user_id { User.current.id }

    trait :with_chart_settings do
      chart_settings = {
          "primary_renderer" => "line",
          "axis_x_column"    => "project",
          "axis_y_type"      => "sum",
          "axis_y_column"    => "estimated_hours",
          "legend_enabled"   => "0",
          "legend"           => {
              "location"  => "nw",
              "placement" => "insideGrid"
          }
      }
      settings { { 'chart_settings' => chart_settings } }
    end
  end

  factory :easy_page do
    sequence(:identifier) { |n| "custom-page#{n}" }
    sequence(:user_defined_name) { |n| "Custom Page #{n}" }
    page_name { 'easy-custom' }
    layout_path { 'easy_page_layouts/two_column_header_first_wider' }
  end

  factory :easy_page_permission do
  end

  factory :document_category, :parent => :enumeration, :class => 'DocumentCategory' do
    sequence(:name) { |n| "TestDocCat#{n}" }
  end

  factory :document do
    project
    association :category, :factory => :document_category
    sequence(:title) { |n| "title#{n}" }
  end

  factory :group do
    sequence(:lastname) { |n| "Group ##{n}" }
    status { Principal::STATUS_ACTIVE }
    admin { false }
    type { "Group" }
  end

  factory :email_address do
    user
    sequence(:address) { |n| "john.doe#{n}@factory.com" }
  end

  factory :watcher do
    association :watchable, :factory => :issue
    user
  end

  factory :easy_entity_action do
    sequence(:name) { |n| "Action n.#{n}" }
    type { 'EasyDisabledEntityAction' }
    active { true }
    use_journal { true }
    author
    execute_as { 'author' }
    period_options { { 'period' => 'every_day', 'time' => 'defined', 'hours' => '00:00' } }
    nextrun_at { Time.now }
  end

end
