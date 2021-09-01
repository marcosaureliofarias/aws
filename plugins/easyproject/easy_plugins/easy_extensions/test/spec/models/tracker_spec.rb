require 'easy_extensions/spec_helper'

describe Tracker, :logged => :admin do
  let(:trackers) { FactoryGirl.create_list(:tracker, 2) }
  let(:issues1) { FactoryGirl.create_list(:issue, 3, :tracker_id => trackers.first) }
  let(:issues2) { FactoryGirl.create_list(:issue, 3, :tracker_id => trackers.last) }

  it 'move issues' do
    issues1; issues2
    trackers.first.move_issues(trackers.last)
    expect(issues1.map { |i| i.reload; i.tracker_id }.uniq).to eq([trackers.last.id])
    expect(issues2.map { |i| i.reload; i.tracker_id }.uniq).to eq([trackers.last.id])
  end
end
