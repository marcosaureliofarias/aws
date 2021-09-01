require 'easy_extensions/spec_helper'

describe EasyRakeTaskEasyMeetingNotifier do
  context 'after meeting change should send email according to the notifications settings' do
    let(:upcoming_meeting) { FactoryBot.create(:easy_meeting, :with_users, emailed: true, start_time: Time.now + 3.day) }
    let(:meeting) { FactoryBot.create(:easy_meeting, :with_users, emailed: true, start_time: Time.now + 9.day) }

    before do
      allow_any_instance_of(EasyMeeting).to receive(:notify_invitees).and_return(false)
    end

    subject(:notifier) { EasyRakeTaskEasyMeetingNotifier.new }

    it 'right_now' do
      allow(upcoming_meeting).to receive(:email_notifications).and_return(:right_now)
      upcoming_meeting.update(all_day: true)
      expect(EasyCalendar::EasyMeetingNotifier).to receive(:call).with(upcoming_meeting)
      notifier.execute
    end

    it 'one_week_before' do
      allow(meeting).to receive(:email_notifications).and_return(:one_week_before)
      with_time_travel(3.days) do
        meeting.update(all_day: true)
        expect(EasyCalendar::EasyMeetingNotifier).to receive(:call).with(meeting)
        notifier.execute
      end
    end
  end
end
