easy_extensions = Redmine::Plugin.installed?(:easy_extensions)

# this block is called every time rails are reloading code
# in development it means after each change in observed file
# in production it means once just after server has started
# in this block should be used require_dependency, but only if necessary.
# better is to place a class in file named by rails naming convency and let it be loaded automatically
# Here goes query registering, custom fields registering and so on
RedmineExtensions::Reloader.to_prepare do

  require 'redmine_test_cases/internals'
  require 'redmine_test_cases/hooks'
  require 'redmine_test_cases/test_case_hooks'
  require 'redmine_test_cases/test_case_issue_execution_hooks'

  # Touch to register subclass
  TestCaseIssueExecutionResult
end

# this block is executed once just after Redmine is started
# means after all plugins are initialized
# it is place for plain requires, not require_dependency
# it should contain hooks, permissions - base class in Redmine is required thus is not reloaded
ActiveSupport.on_load(:easyproject, yield: true) do
  require 'redmine_test_cases/proposer' if easy_extensions

  Redmine::AccessControl.map do |map|
    map.project_module :test_cases do |pmap|
      pmap.permission :view_test_plans, { test_plans: [:index, :show, :autocomplete] }, read: true
      pmap.permission :manage_test_plans, { test_plans: [:new, :create, :edit, :update, :destroy] }

      pmap.permission :view_test_cases, { test_cases: [:index, :show, :context_menu, :autocomplete, :issues_autocomplete] }, read: true
      pmap.permission :manage_test_cases, { test_cases: [:new, :create, :edit, :update, :destroy, :bulk_edit, :bulk_update, :statistics, :statistics_layout], issue_test_cases: [:list, :add] }

      pmap.permission :view_test_case_issue_executions, { test_case_issue_executions: [:index, :show, :autocomplete, :context_menu] }, read: true
      pmap.permission :manage_test_case_issue_executions, { test_case_issue_executions: [:new, :create, :edit, :update, :destroy, :bulk_edit, :bulk_update] }

      pmap.permission :import_test_cases, {
          test_cases_csv_import: [:index, :new, :create, :edit, :update, :destroy, :show, :fetch_preview, :assign_import_attribute, :destroy_import_attribute, :import],
          attachments: [:upload]
      }
    end
  end

  Redmine::MenuManager.map :top_menu do |menu|
    menu.push :test_cases, { controller: 'test_cases', action: 'index', project_id: nil },
              html: {class: 'icon icon-test-cases'}, caption: :label_test_cases,
              if: Proc.new { User.current.allowed_to_globally? :view_test_cases }
  end

  Redmine::MenuManager.map :project_menu do |menu|
    menu.push :test_cases, { controller: 'test_cases', action: 'index' }, param: :project_id, caption: :label_test_cases
  end

  CustomFieldsHelper::CUSTOM_FIELDS_TABS << {name: 'TestPlanCustomField', partial: 'custom_fields/index', label: :label_test_plans}
  CustomFieldsHelper::CUSTOM_FIELDS_TABS << {name: 'TestCaseCustomField', partial: 'custom_fields/index', label: :label_test_cases}
  CustomFieldsHelper::CUSTOM_FIELDS_TABS << {name: 'TestCaseIssueExecutionCustomField', partial: 'custom_fields/index', label: :label_test_case_issue_executions}

  Redmine::Search.map do |search|
    search.register :test_cases
  end

  Redmine::Activity.map do |activity|
    activity.register :test_cases, {class_name: %w(TestCase), default: false}
  end

  if easy_extensions
    EasyQuery.register('TestCaseQuery')
    EasyQuery.register('TestCaseIssueExecutionQuery')

    require_dependency 'easy_test_case_csv_import'
  end

end
