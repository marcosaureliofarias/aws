require 'easy_extensions/spec_helper'

describe EasyCalendarController, logged: :admin, if: EasyScheduler.easy_calendar? && EasyScheduler.easy_entity_activities? do

  describe '#user_availability' do
    let(:user) { User.current }
    let(:start_time) { user.user_time_in_zone("2018-05-09 09:00") }
    let(:end_time) { user.user_time_in_zone("2018-05-09 11:00") }

    context 'json' do
      let(:params) do
        {
          user_id: user.id,
          start: start_time.to_i,
          end: end_time.to_i
        }
      end

      it 'with entity activities' do
        event = FactoryBot.create(:easy_entity_activity, start_time: start_time, end_time: end_time, easy_entity_activity_users: [user])
        get :user_availability, params: params.merge(with_easy_entity_activities: true), format: :json
        json = JSON.parse(response.body).first
        expect(json).to include('id' => "easy_entity_activity-#{event.id}", 'title' => "#{event.entity.name}: #{event.category.name}")
        expect(json).to include('start' => user.user_time_in_zone(event.start_time).iso8601, 'end' => user.user_time_in_zone(event.end_time).iso8601)
        expect(json).to include('allDay' => event.all_day, 'editable' => true, 'url' => "/easy_crm_cases/#{event.entity_id}")
        expect(json).to include('eventType' => 'easy_entity_activity', 'entityId' => event.entity_id, 'entityType' => 'EasyCrmCase')
      end

      it 'with my ical events' do
        event = FactoryBot.create(:easy_icalendar_event, dtstart: start_time, dtend: end_time)
        get :user_availability, params: params.merge(with_ical: true, ical_ids: [event.easy_icalendar.id]), format: :json
        json = JSON.parse(response.body).first
        expect(json).to include('id' => "easy_ical_event-#{event.uid}", 'title' => event.summary, 'url' => event.url)
        expect(json).to include('allDay' => false, 'editable' => false, 'isPrivate' => false, 'eventType' => 'ical_event')
        expect(json).to include('end' => user.user_time_in_zone(event.dtend).iso8601, 'start' => user.user_time_in_zone(event.dtstart).iso8601)
      end
    end
  end

end
