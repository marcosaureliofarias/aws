require File.expand_path('../../spec_helper', __FILE__)

describe Version, logged: :admin do
  let(:version) { FactoryBot.create(:version) }
  let(:closed_status) { FactoryBot.create(:issue_status, :closed) }
  let(:closed_issue) { FactoryBot.create(:issue, fixed_version: version, project: version.project, estimated_hours: 0, status: closed_status)}
  let(:in_progress_issue) { FactoryBot.create(:issue, fixed_version: version, project: version.project, estimated_hours: 0, done_ratio: 50)}
  let(:not_estimated_issue) { FactoryBot.create(:issue, fixed_version: version, project: version.project, estimated_hours: nil, done_ratio: 0)}
  let(:estimated_issue) { FactoryBot.create(:issue, fixed_version: version, project: version.project, estimated_hours: 10, done_ratio: 100)}

  it 'progress' do
    closed_issue; in_progress_issue
    expect(version.visible_fixed_issues.closed_percent).to eq 50
    expect(version.visible_fixed_issues.completed_percent).to eq 75
  end

  it 'progress 2' do
    not_estimated_issue; estimated_issue
    expect(version.visible_fixed_issues.closed_percent).to eq 0
    expect(version.visible_fixed_issues.completed_percent).to eq 100
  end

end
