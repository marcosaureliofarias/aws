require 'easy_extensions/spec_helper'

describe 'EasyEntityActivityCalendarEvent', if: Redmine::Plugin.installed?(:easy_crm) do
  let(:start_time) { User.current.user_time_in_zone("2018-05-09 09:00") }
  let(:end_time) { User.current.user_time_in_zone("2018-05-09 11:00") }
  let(:entity_acitivity) { FactoryGirl.create(:easy_entity_activity, start_time: start_time, end_time: end_time) }
  
  subject { EasyEntityActivityCalendarEvent.create(entity_acitivity) }

  it 'url should not raise error' do
    expect{ subject.url }.not_to raise_exception
  end

  it 'empty end_time ' do
    event = subject
    event.object.end_time = nil
    event.object.save
    expect(event.end).to eq((start_time + 15.minutes).iso8601)
  end

  it 'not empty end_time' do
    expect(subject.end).to eq(end_time.iso8601)
  end

  it 'event_type' do
    expect(subject.event_type).to eq('easy_entity_activity')
  end

end
