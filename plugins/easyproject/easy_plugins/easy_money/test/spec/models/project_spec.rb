require 'easy_extensions/spec_helper'

describe Project, without_cache: true do
  describe '#with_easy_money_setting' do
    let!(:project) { FactoryBot.create(:project, number_of_issues: 0) }

    before do
      FactoryBot.create(:easy_money_settings, name: 'new_easy_money_setting', value: '1')
    end

    context 'find project by global setting' do
      it do
        expect(Project.with_easy_money_setting('new_easy_money_setting', '1')).to eq([project])
        expect(Project.with_easy_money_setting('new_easy_money_setting', '0')).to be_empty
      end
    end

    context 'project setting overrides global setting' do
      before do
        FactoryBot.create(:easy_money_settings, name: 'new_easy_money_setting', project: project, value: '0')
      end

      it do
        expect(Project.with_easy_money_setting('new_easy_money_setting', '1')).to be_empty
        expect(Project.with_easy_money_setting('new_easy_money_setting', '0')).to eq([project])
      end
    end

    context 'load only project with the valid setting' do
      let(:project_with_global_setting) { FactoryBot.create(:project, number_of_issues: 0) }

      before do
        FactoryBot.create(:easy_money_settings, name: 'new_easy_money_setting', project: project, value: '0')
      end

      it do
        expect(Project.with_easy_money_setting('new_easy_money_setting', '1')).to eq([project_with_global_setting])
        expect(Project.with_easy_money_setting('new_easy_money_setting', '0')).to eq([project])
      end
    end
  end

  describe '.easy_money_rates' do
    context '.delete_all' do

      let(:project) { FactoryBot.create(:project) }

      it "doesn't leave global rate behind" do
        FactoryBot.create(:easy_money_rate, unit_rate: 15, project: project)
        expect(EasyMoneyRate.first).not_to be_nil
        project.easy_money_rates.delete_all
        # before the fix, this would contain EasyMoneyRate with project_id=nill
        expect(EasyMoneyRate.first).to be_nil
      end

      it "doesn't clear already set global vat_rates" do
        emr_global = FactoryBot.create(:easy_money_rate, unit_rate: 16)
        em_project = FactoryBot.create(:easy_money_rate, unit_rate: 15, project: project)
        expect(project.easy_money_rates).not_to be_empty
        expect(EasyMoneyRate.all.size).to be(2)

        project.easy_money_rates.delete_all
        expect(EasyMoneyRate.all.size).to be(1)
        expect(EasyMoneyRate.first).to eq(emr_global)
      end

      it "doesn't fail for no vat_rates in the project" do
        emr_global = FactoryBot.create(:easy_money_rate, unit_rate: 16)
        project.easy_money_rates.delete_all
        expect(EasyMoneyRate.all.size).to be(1)
        expect(EasyMoneyRate.first).to eq(emr_global)
      end
    end
  end

  describe '#easy_money_setting_condition' do
    context 'it should be proxy for the with_easy_money_setting scope' do
      before do
        allow(Project).to receive(:with_easy_money_setting)
      end

      it do
        Project.easy_money_setting_condition(Project, 'new_easy_money_setting')
        expect(Project).to have_received(:with_easy_money_setting).with('new_easy_money_setting', '1')
      end
    end
  end

  describe 'planned_hours_and_rate' do
    let(:project) { FactoryBot.create :project, number_of_issues: 0, easy_currency_code: 'EUR', enabled_module_names: ['easy_money', 'issue_tracking'] }
    let(:easy_money_rate_type) { FactoryBot.create(:easy_money_rate_type) }
    let(:easy_money_rate) { FactoryBot.create(:easy_money_rate, easy_currency_code: 'CZK') }
    let(:user) { FactoryBot.create :user }
    let(:issue) { FactoryBot.create :issue, project: project, estimated_hours: 2, assigned_to: user }

    it 'sum' do
      issue
      EasyMoneyRatePriority.create!(rate_type: easy_money_rate_type, project: project, entity_type: 'User', position: 1)
      allow(project.easy_money_settings).to receive(:expected_payroll_expense_type).and_return('planned_hours_and_rate')
      allow(EasyMoneyRatePriority).to receive(:rate_priorities_by_rate_type_and_project).and_return(EasyMoneyRatePriority.all)
      allow(EasyMoneyRate).to receive(:find_rate).and_return(easy_money_rate)
      allow(EasyCurrencyExchangeRate).to receive(:find_exchange_rate_value).with('CZK', 'EUR', Date.current).and_return(2)
      expect(project.easy_money.sum_expected_payroll_expenses).to eq(4000.0)
    end
  end
end
