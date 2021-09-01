require 'easy_extensions/spec_helper'

describe EasyRoom do

  describe '#available_for_date?' do
    let(:easy_room) { FactoryBot.create(:easy_room) }
    let(:easy_meeting) do
      FactoryBot.create(:easy_meeting,
                        start_time: Time.new(2018, 1, 1, 2, 30),
                        end_time: Time.new(2018, 1, 1, 3, 30),
                        easy_room: easy_room)
    end

    context 'conflicts' do
      context 'at the end of a meeting' do
        it do
          result = easy_room.available_for_date?(easy_meeting.end_time.advance(seconds: -1),
                                                 easy_meeting.end_time.advance(hours: 1))
          expect(result).to be_falsey
        end
      end

      context 'at the start of a meeting' do
        it do
          result = easy_room.available_for_date?(easy_meeting.start_time.advance(hours: -1),
                                                 easy_meeting.start_time.advance(seconds: 1))
          expect(result).to be_falsey
        end
      end

      context 'meeting covers whole period' do
        it do
          result = easy_room.available_for_date?(easy_meeting.start_time.advance(seconds: -1),
                                                 easy_meeting.end_time.advance(seconds: 1))
          expect(result).to be_falsey
        end
      end

      context 'meeting is inside of given period' do
        it do
          result = easy_room.available_for_date?(easy_meeting.start_time.advance(seconds: 1),
                                                 easy_meeting.end_time.advance(seconds: -1))
          expect(result).to be_falsey
        end
      end

      context 'meeting with the same period & current_meeting_id argument given' do
        it do
          result = easy_room.available_for_date?(easy_meeting.start_time, easy_meeting.end_time, easy_meeting.id + 1)
          expect(result).to be_falsey
        end
      end
    end

    context 'without conflicts' do

      context 'meeting with the same period & current_meeting_id argument given' do
        it 'ignores meeting with id == current_meeting_id' do
          result = easy_room.available_for_date?(easy_meeting.start_time, easy_meeting.end_time, easy_meeting.id)
          expect(result).to be_truthy
        end
      end

      context 'meeting finishes before' do
        it do
          result = easy_room.available_for_date?(easy_meeting.start_time.advance(hours: -1),
                                                 easy_meeting.start_time.advance(seconds: -1))
          expect(result).to be_truthy
        end
      end

      context 'meeting starts after' do
        it do
          result = easy_room.available_for_date?(easy_meeting.end_time.advance(seconds: 1),
                                                 easy_meeting.end_time.advance(hours: 1))
          expect(result).to be_truthy
        end
      end

      context 'meeting finishes before - same time' do
        it do
          result = easy_room.available_for_date?(easy_meeting.start_time.advance(hours: -1),
                                                 easy_meeting.start_time)
          expect(result).to be_truthy
        end
      end

      context 'meeting starts after - same time' do
        it do
          result = easy_room.available_for_date?(easy_meeting.end_time, easy_meeting.end_time.advance(hours: 1))
          expect(result).to be_truthy
        end
      end

    end
  end

end
