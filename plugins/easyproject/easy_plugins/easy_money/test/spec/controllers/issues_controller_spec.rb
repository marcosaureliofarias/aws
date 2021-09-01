require 'easy_extensions/spec_helper'

describe IssuesController, logged: :admin do
  let(:project) { FactoryBot.create(:project, number_of_issues: 0, add_modules: ['easy_money', 'issue_tracking']) }
  let!(:issue) { FactoryBot.create(:issue, project: project) }
  let(:time_entry_activity_zero) { FactoryBot.create(:time_entry_activity, projects: [project]) }
  let(:time_entry_activity_nonzero) { FactoryBot.create(:time_entry_activity, projects: [project]) }

  let(:easy_money_rate_type) { FactoryBot.create(:easy_money_rate_type) }

  let(:easy_money_rate1) { EasyMoneyRate.create(rate_type_id: easy_money_rate_type.id, entity: time_entry_activity_nonzero, unit_rate: 10) }
  let(:easy_money_rate) { EasyMoneyRate.create(rate_type_id: easy_money_rate_type.id, entity: time_entry_activity_zero, unit_rate: 0) }

  let(:easy_money_rate_priority) { EasyMoneyRatePriority.create(rate_type_id: easy_money_rate_type.id, entity_type: 'TimeEntryActivity', position: 0, project_id: project.id) }

  def easy_money_calculation(activity, expectation)
    easy_money_rate_priority
    easy_money_rate
    easy_money_rate1
    expect {
      put :update, params: { id: issue, time_entry: { hours: 5, activity_id: activity } }
    }.to change(TimeEntry, :count).by(1)
    issue.reload
    expect(issue.easy_money_time_entry_expenses.first.price).to eq(expectation)
  end

  it 'updates issue with 0 money rate for spent time' do
    easy_money_calculation(time_entry_activity_zero, 0)
  end

  it 'updates issue with nonzero money rate for spent time' do
    easy_money_calculation(time_entry_activity_nonzero, 50)
  end

end
