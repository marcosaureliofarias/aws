require 'easy_extensions/spec_helper'

describe EasyMoneyRate do
  describe '#unit_rate' do
    let(:easy_currency_eur) { FactoryBot.create(:easy_currency, :eur) }
    let(:easy_currency_czk) { FactoryBot.create(:easy_currency, :czk) }

    let(:prev_month) { current_date.prev_month }
    let(:current_date) { Date.current }
    let(:user) { FactoryBot.create(:user) }
    let(:easy_money_rate_type) { FactoryBot.create(:easy_money_rate_type) }

    before do
      exchange_rates = [
          {base_code: easy_currency_eur.iso_code, to_code: easy_currency_czk.iso_code, rate: 25.0, valid_on: prev_month},
          {base_code: easy_currency_czk.iso_code, to_code: easy_currency_eur.iso_code, rate: 1/25.0, valid_on: prev_month},
          {base_code: easy_currency_eur.iso_code, to_code: easy_currency_czk.iso_code, rate: 26.5, valid_on: current_date},
          {base_code: easy_currency_czk.iso_code, to_code: easy_currency_eur.iso_code, rate: 1/26.5, valid_on: current_date}
      ]

      EasyCurrencyExchangeRate.import exchange_rates
    end

    it 'created a month ago' do
      easy_money_rate = EasyMoneyRate.create!(entity: user, rate_type: easy_money_rate_type, easy_currency: easy_currency_eur, unit_rate: 10, updated_at: prev_month)
      expect(easy_money_rate.unit_rate(easy_currency_czk.iso_code)).to eq(265.0)
      expect(easy_money_rate.unit_rate(easy_currency_czk.iso_code, prev_month)).to eq(250.0)
    end

    it 'created today' do
      easy_money_rate = EasyMoneyRate.create!(entity: user, rate_type: easy_money_rate_type, easy_currency: easy_currency_eur, unit_rate: 10, updated_at: current_date)
      expect(easy_money_rate.unit_rate(easy_currency_czk.iso_code)).to eq(265.0)
      expect(easy_money_rate.unit_rate(easy_currency_czk.iso_code, prev_month)).to eq(250.0)
    end
  end

  context 'project' do
    let!(:project) { FactoryGirl.create(:project, :enabled_module_names => ['easy_money'])}
    let!(:project_with_subprojects) { FactoryGirl.create(:project, :with_subprojects, number_of_subprojects: 1, :enabled_module_names => ['easy_money'])}
    let!(:project2) { FactoryGirl.create(:project, :enabled_module_names => ['easy_money'])}

    it 'global' do
      expect(EasyMoneyRate.affected_projects('global', 'EasyMoneyRateUser', nil).count).to eq(3)
      expect(EasyMoneyRate.affected_projects('global', 'EasyMoneyRateTimeEntryActivity', nil).count).to eq(3)
      expect(EasyMoneyRate.affected_projects('global', 'EasyMoneyRateRole', nil).count).to eq(3)
      expect(EasyMoneyRate.affected_projects('global', 'EasyMoneyOtherSettings', nil).count).to eq(3)
    end

    it 'all' do
      expect(EasyMoneyRate.affected_projects('all', 'EasyMoneyRateUser', nil).count).to eq(3)
    end

    it 'self' do
      expect(EasyMoneyRate.affected_projects('self', 'EasyMoneyRateUser', project.id)).to eq([project])

      expect(EasyMoneyRate.affected_projects('self', 'EasyMoneyRateUser', '0')).to eq([])
    end

    it 'self and descendants' do
      project_with_subprojects.reload
      expect(EasyMoneyRate.affected_projects('self_and_descendants', 'EasyMoneyRateUser', project_with_subprojects.id).collect(&:id)).to eq(project_with_subprojects.self_and_descendants.active.non_templates.has_module(:easy_money).collect(&:id))

      expect(EasyMoneyRate.affected_projects('self_and_descendants', 'EasyMoneyRateUser', 0)).to eq([])
    end
  end
end
