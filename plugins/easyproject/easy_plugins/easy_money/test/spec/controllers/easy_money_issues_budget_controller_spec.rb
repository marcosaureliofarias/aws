require 'easy_extensions/spec_helper'

describe EasyMoneyIssuesBudgetController, logged: :admin do

  render_views

  let(:project) { FactoryGirl.create(:project, enabled_module_names: ['easy_money', 'issue_tracking'], number_of_issues: 1) }
  let(:project2) { FactoryGirl.create(:project, enabled_module_names: ['issue_tracking'], number_of_issues: 1) }

  def with_money_settings(&block)
    EasyMoneySettings.create!(name: 'use_easy_money_for_issues', value: '1')
    yield
  ensure
    EasyMoneySettings.where(name: 'use_easy_money_for_issues').delete_all
  end

  it 'renders grouped index' do
    project2; project
    with_money_settings do
      get :index, params: {set_filter: '1', group_by: ['project'], show_sum_row: '1', column_names: ['actual_personal_costs']}
      expect(response).to be_successful
    end
  end
end