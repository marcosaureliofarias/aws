require 'easy_extensions/spec_helper'

describe 'EasyBudgetSheetQuery', logged: :admin, skip: !Redmine::Plugin.installed?(:easy_budgetsheet), deletion: true do
  let(:project) { FactoryBot.create(:project, :enabled_module_names => ['easy_money', 'issue_tracking', 'time_tracking'])}
  let(:issue) { FactoryBot.create(:issue, project: project) }
  let(:time_entry) { FactoryBot.create(:time_entry, issue: issue, project: project) }
  let(:easy_currency_eur) { FactoryBot.create(:easy_currency, :eur, activated: true) }
  let(:easy_money_rate) { FactoryBot.create(:easy_money_rate) }
  let(:easy_money_time_entry_expense) { FactoryBot.create(:easy_money_time_entry_expense, time_entry: time_entry, rate_type: easy_money_rate.rate_type) }

  it 'rate columns' do
    allow(EasyEntityWithCurrency).to receive(:initialized?).and_return(true)
    easy_currency_eur
    EasyCurrency.reinitialize_tables
    easy_money_time_entry_expense
    q = EasyBudgetSheetQuery.new
    q.easy_currency_code = 'EUR'
    rate_type = easy_money_rate.rate_type
    column = q.get_column(EasyMoneyTimeEntryExpense::EASY_QUERY_PREFIX + rate_type.name)
    expect(column).not_to be_nil
    q.group_by = 'project'
    q.column_names = [column.name.to_s]
    q.sort_criteria = [[column.name.to_s, 'asc']]
    expect(q.entity_sum(column).to_f).to eq(10.0)
    expect(q.entities.size).to eq(1)
  end
end
