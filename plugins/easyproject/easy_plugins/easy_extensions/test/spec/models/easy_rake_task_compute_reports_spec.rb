require 'easy_extensions/spec_helper'

describe 'EasyRakeTaskComputeReports' do
  let!(:issue) { FactoryBot.create(:issue) }
  let!(:journal) { Journal.create!(journalized: issue, user: User.current) }
  let!(:status) { FactoryBot.create(:issue_status) }
  let!(:detail) { JournalDetail.create!(journal_id: journal.id, property: 'attr', prop_key: 'status_id', old_value: issue.status_id.to_s, value: status.id.to_s) }

  it 'execute' do
    expect {
      EasyRakeTaskComputeReports.new.execute
    }.to change(EasyReportIssueStatus, :count).by(1)
  end
end
