require 'easy_extensions/spec_helper'

describe EasyMoneyCrmCasesBudgetController, logged: :admin, skip: !Redmine::Plugin.installed?(:easy_crm) || !Redmine::Plugin.installed?(:easy_contacts) do

  render_views

  let(:project) { FactoryBot.create(:project, enabled_module_names: ['easy_money', 'easy_crm'], number_of_issues: 0) }
  let(:easy_crm_case) { FactoryBot.create(:easy_crm_case, project: project) }

  def with_money_settings(&block)
    EasyMoneySettings.create!(name: 'use_easy_money_for_easy_crm_cases', value: '1')
    yield
  ensure
    EasyMoneySettings.where(name: 'use_easy_money_for_easy_crm_cases').delete_all
  end

  it 'index' do
    easy_crm_case
    with_money_settings do
      get :index, params: {set_filter: '1', column_names: ['actual_incomes_without_vat', 'main_easy_contacts.lastname']}
      expect(response).to be_successful
      expect(assigns(:entities).count).to eq(1)
    end
  end
end