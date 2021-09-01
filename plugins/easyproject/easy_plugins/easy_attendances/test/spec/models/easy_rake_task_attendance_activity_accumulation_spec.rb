require 'easy_extensions/spec_helper'

describe EasyRakeTaskAttendanceActivityAccumulation do

  let!(:user)      { FactoryGirl.create(:admin_user) }
  let(:limit_days) { 10 }

  it 'saves accumulated days' do
    EasyAttendanceActivity.all.each do |activity|
      limit = EasyAttendanceActivityUserLimit.create(:user_id => user.id, :easy_attendance_activity_id => activity.id, :days => limit_days)
      limit.save
    end

    rake_task = EasyRakeTaskAttendanceActivityAccumulation.new(:active => true, :settings => {}, :period => :monthly, :interval => 12,
                                      :next_run_at => Time.local(Date.today.year, 12, 31, 23, 0))
    # $stdout.stubs(:puts)

    expected_days = limit_days * 2
    rake_task.execute
    expect( user.easy_attendance_activity_user_limits.first.total_user_days ).to eq( expected_days )

    expected_days = limit_days * 3
    rake_task.execute
    expect( user.easy_attendance_activity_user_limits.first.total_user_days ).to eq( expected_days )
  end

end
