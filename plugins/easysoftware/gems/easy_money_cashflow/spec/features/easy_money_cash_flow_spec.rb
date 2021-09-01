require_relative '../spec_helper'

RSpec.feature 'Easy money cash flow', logged: :admin, js: true, slow: true do

  let(:project) { FactoryBot.create(:project, enabled_module_names: ['easy_money'])}
  let(:issue) { FactoryBot.create(:issue, project: project) }
  let(:easy_money_expected_expenses) { FactoryBot.create_list(:easy_money_expected_expense, 30, spent_on: Date.today, price2: 1)}
  let(:issue_easy_money_expected_expenses) { FactoryBot.create_list(:easy_money_expected_expense, 2, spent_on: Date.today, price2: 1, entity: issue)}
  
  scenario 'zoom links' do
    visit easy_money_cash_flow_path(set_filter: '1', show_sum_row: '1',
                                    column_names: ['name', 'empe_cashflow_prediction_price2'],
                                    period_date_period: 'current_month', period_date_period_type: '1')
    expect(page).to have_css('.easy-query-listing-links')
    expect(page).to have_css('.easy-query-heading-controls')
  end

  scenario 'show all' do
    issue_easy_money_expected_expenses
    visit easy_money_cash_flow_path(set_filter: '1', show_sum_row: '1',
                                    easy_query: { columns_to_export: 'all' },
                                    period_date_period: 'current_month', period_date_period_type: '1')
    expect(page).to have_css('#content')
  end

end if Redmine::Plugin.installed?(:easy_money)
