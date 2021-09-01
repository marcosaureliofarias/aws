require 'easy_extensions/spec_helper'

describe EasyMoneyTimeEntryExpense, type: :model, deletion: true do
  let(:easy_currency_eur) { FactoryBot.create(:easy_currency, :eur) }
  let(:easy_currency_czk) { FactoryBot.create(:easy_currency, :czk) }
  let(:time_entry_date) { 1.month.ago }
  let(:current_date) { Date.current }
  let(:user) { FactoryBot.create :user }
  let(:project) { FactoryBot.create :project, number_of_issues: 0, easy_currency: easy_currency_eur}
  let(:issue) { FactoryBot.create :issue, project: project }
  let(:time_entry) { FactoryBot.create(:time_entry, issue: issue, user: user, spent_on: time_entry_date, hours: 10) }
  let(:easy_money_rate_type) { FactoryBot.create(:easy_money_rate_type) }

  subject { EasyMoneyTimeEntryExpense.last }

  before do
    allow_any_instance_of(TimeEntry).to receive(:update_easy_money_time_entry_expense).and_return(true)
    allow(EasyEntityWithCurrency).to receive(:initialized?).and_return(true)

    exchange_rates = [
        {base_code: easy_currency_eur.iso_code, to_code: easy_currency_czk.iso_code, rate: 27.5, valid_on: (time_entry_date - 2.months)},
        {base_code: easy_currency_czk.iso_code, to_code: easy_currency_eur.iso_code, rate: 1/27.5, valid_on: (time_entry_date - 2.months)},
        {base_code: easy_currency_eur.iso_code, to_code: easy_currency_czk.iso_code, rate: 25.0, valid_on: time_entry_date},
        {base_code: easy_currency_czk.iso_code, to_code: easy_currency_eur.iso_code, rate: 1/25.0, valid_on: time_entry_date},
        {base_code: easy_currency_eur.iso_code, to_code: easy_currency_czk.iso_code, rate: 26.5, valid_on: current_date},
        {base_code: easy_currency_czk.iso_code, to_code: easy_currency_eur.iso_code, rate: 1/26.5, valid_on: current_date}
    ]

    EasyCurrencyExchangeRate.import exchange_rates

    EasyMoneyRatePriority.create!(rate_type: easy_money_rate_type, project: project, entity_type: 'User', position: 1)

    EasyCurrency.reinitialize_tables
  end


  it 'rate was created in the past' do
    EasyMoneyRate.create!(project: project, entity: user, rate_type: easy_money_rate_type, easy_currency: easy_currency_czk, unit_rate: 400, updated_at: time_entry_date.prev_month)
    EasyMoneyTimeEntryExpense.update_easy_money_time_entry_expense(time_entry)

    is_expected.to have_attributes(price: 160.0, price_EUR: 160.0, price_CZK: 4000.0)
  end

  it 'rate was created today' do
    EasyMoneyRate.create!(project: project, entity: user, rate_type: easy_money_rate_type, easy_currency: easy_currency_czk, unit_rate: 400, updated_at: current_date)
    EasyMoneyTimeEntryExpense.update_easy_money_time_entry_expense(time_entry)

    is_expected.to have_attributes(price: 160.0, price_EUR: 160.0, price_CZK: 4000.0)
  end

end
