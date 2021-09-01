# encoding: utf-8
require 'easy_extensions/spec_helper'

describe EasyCalendarMailer, type: :mailer, logged: true do
  describe 'easy_meeting_removal' do

    let(:invited_user) { FactoryBot.create(:user) }
    let(:meeting) { FactoryBot.create(:easy_meeting, start_time: { 'date' => User.current.today, 'time' => '11:30' },  end_time: { 'date' => User.current.today, 'time' => '12:30' }) }

    let(:easy_meeting_hash) { meeting.attributes.to_json(only: %w{name all_day start_time end_time}) }
    
    it 'assigns @start_time' do
      with_user_pref(time_zone: 'Tokyo') do

        body = described_class.easy_meeting_removal(invited_user, easy_meeting_hash).body.encoded
        time = invited_user.user_time_in_zone(meeting.start_time)

        expect(body).to match("#{I18n.l(time.to_date)}")
        expect(body).to match("#{I18n.l(time, format: :time)}")

        # user current

        body = described_class.easy_meeting_removal(User.current, easy_meeting_hash).body.encoded

        time = User.current.user_time_in_zone(meeting.start_time)

        expect(body).to match("#{I18n.l(time.to_date)}")
        expect(body).to match("#{I18n.l(time, format: :time)}")
      end
    end

    it 'assigns @end_time' do
      with_user_pref(time_zone: 'Tokyo') do

        body = described_class.easy_meeting_removal(invited_user, easy_meeting_hash).body.encoded
        time = invited_user.user_time_in_zone(meeting.end_time)

        expect(body).to match("#{I18n.l(time.to_date)}")
        expect(body).to match("#{I18n.l(time, format: :time)}")

        # user current

        body = described_class.easy_meeting_removal(User.current, easy_meeting_hash).body.encoded

        time = User.current.user_time_in_zone(meeting.end_time)

        expect(body).to match("#{I18n.l(time.to_date)}")
        expect(body).to match("#{I18n.l(time, format: :time)}")
      end
    end
  end
end
