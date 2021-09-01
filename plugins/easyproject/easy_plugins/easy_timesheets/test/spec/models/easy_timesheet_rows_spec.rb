require 'easy_extensions/spec_helper'

describe EasyTimesheets::EasyTimesheetRow do
  include_context 'easy timesheet with rows'

  around(:each) do |example|
    with_easy_settings('easy_timesheets_over_time' => '1') { example.run }
  end

  let(:time_entry) { spy(project: nil, issue: nil, activity: nil) }
  subject { easy_timesheet.rows.last }

  it '#dom_id' do
    expect(subject.dom_id).to eq('no_project-no_issue-no_activity-over_time-true')
  end

  it '#id' do
    expect(subject.id).to eq('no_project-no_issue-no_activity-over_time-true')
  end

  it '#to_param' do
    expect(subject.to_param).to eq('no_project-no_issue-no_activity-over_time-true')
  end

  it 'overtime_fit_to_time_entry?' do
    expect(subject.fit_to_time_entry?(time_entry, true)).to be true
  end

end
