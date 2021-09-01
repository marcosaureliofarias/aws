require 'easy_extensions/spec_helper'

describe EasyCalendarController, logged: :admin do

  describe 'with user and module' do
    let!(:page_module) { EasyPageZoneModule.create!(
      easy_pages_id: 1,
      easy_page_available_zones_id: 1,
      easy_page_available_modules_id: 43,
      user_id: User.current.id,
      settings: HashWithIndifferentAccess.new({enabled_calendars: ['easy_meeting_calendar'], display_from: '9:00', display_to: '20:00'})
    )}

    context 'GET feed' do
      it "works with invalid date limits (happens when module is collapsed)" do
        get :feed, params: {module_id: page_module.id, start: 'NaN', end: 'NaN', format: 'json'}
        expect( response ).to be_successful
      end
    end
  end

  describe '#user_availability' do
    let(:user) { User.current }
    let(:start_time) { user.user_time_in_zone("2018-05-09 09:00") }
    let(:end_time) { user.user_time_in_zone("2018-05-09 11:00") }
    let(:params) do
      {
        user_id: user.id,
        start: start_time.to_i,
        end: end_time.to_i
      }
    end

    context 'json' do
      it 'with meeting' do
        meeting = FactoryGirl.create(:easy_meeting, user_ids: [user.id], start_time: start_time, end_time: end_time)
        get :user_availability, params: params, format: 'json'
        json = JSON.parse(response.body).first
        expect(json).to include('title' => meeting.name, 'id' => "easy_meeting-#{meeting.id}", 'eventType' => 'meeting')
        expect(json).to include('end' => user.user_time_in_zone(meeting.end_time).iso8601, 'start' => user.user_time_in_zone(meeting.start_time).iso8601)
        expect(json).to include('editable' => true, 'allDay' => meeting.all_day, 'url' => "/easy_meetings/#{meeting.id}", 'location' => nil, 'confirmed' => true)

      end

      it 'with attendance', skip: !Redmine::Plugin.installed?(:easy_attendances) do
        attendance = FactoryGirl.create(:vacation_easy_attendance, arrival: start_time, departure: end_time, user: user)
        get :user_availability, params: params, format: 'json'
        json = JSON.parse(response.body).first
        expect(json).to include('title' => attendance.easy_attendance_activity.name, 'eventType' => 'easy_attendance', 'id' => "availability-easy-attendance-calendar-event-#{attendance.id}")
        expect(json).to include('end' => User.current.user_time_in_zone(attendance.departure).iso8601, 'start' => User.current.user_time_in_zone(attendance.arrival).iso8601)
        expect(json).to include('editable' => true, 'confirmed' => true, 'allDay' => false, 'url' => "/easy_attendances/#{attendance.id}")
      end

      it 'includes room and location' do
        room = FactoryBot.create(:easy_room, name: 'my room')
        meeting = FactoryBot.create(:easy_meeting, user_ids: [user.id], start_time: start_time, end_time: end_time, place_name: 'my place', easy_room: room)
        get :user_availability, params: params, format: 'json'
        json = JSON.parse(response.body).first
        expect(json).to include('room' => 'my room', 'placeName' => 'my place')
      end
    end
  end
end
