FactoryGirl.define do

  factory :easy_query, :class => EasyQuery.registered_subclasses.keys.reject { |q| q.start_with?('EasyUserAllocation') }.sample do
    name { 'Test query' }
    group_by { nil }
    load_groups_opened { true }
  end

  factory :easy_issue_query, :parent => :easy_query, :class => 'EasyIssueQuery' do
    name { 'TestIssueQuery' }
  end

  factory :easy_project_query, :parent => :easy_query, :class => 'EasyProjectQuery' do
    name { 'TestProjectQuery' }
  end

  factory :easy_time_entry_query, :parent => :easy_query, :class => 'EasyTimeEntryQuery' do
    name { 'TestTimeEntryQuery' }
  end

  factory :easy_invoice_proforma_query, :parent => :easy_query, :class => 'EasyInvoiceProformaQuery' do
    name { 'TestInvoiceProformaQuery' }
  end if Redmine::Plugin.installed?(:easy_invoicing)

  factory :easy_budget_sheet_query, :parent => :easy_query, :class => 'EasyBudgetSheetQuery' do
    name { 'TestBudgetSheetQuery' }

    column_names { ['project', 'issue', 'spent_on', 'user', 'hours', 'estimated_hours'] }
    show_sum_row { true }
    load_groups_opened { false }
  end

end
