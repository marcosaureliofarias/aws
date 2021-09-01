require 'easy_extensions/spec_helper'

describe 'EasyAttendanceCalendarEvent', if: Redmine::Plugin.installed?(:easy_attendances) do
  let(:entity_acitivity) { FactoryGirl.create(:easy_attendance) }
  
  subject { EasyAttendanceCalendarEvent.create(entity_acitivity) }

  it 'event_type' do
    expect(subject.event_type).to eq('easy_attendance')
  end
end
