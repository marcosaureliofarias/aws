require 'easy_extensions/spec_helper'

describe EasyAutoCompletesController, logged: :admin do
  let!(:easy_room) { FactoryBot.create(:easy_room) }
  let!(:easy_room2) { FactoryBot.create(:easy_room) }
  let(:easy_meeting) do
    FactoryBot.create(:easy_meeting,
                      start_time: Time.new(2018, 1, 1, 2, 30),
                      end_time: Time.new(2018, 1, 1, 3, 30),
                      easy_room: easy_room)
  end

  describe 'GET index?autocomplete_action=room_availability_for_date_time' do
    it 'returns JSON response with available room with given name as term' do
      expected_result = [
        { 'value' => easy_room.name_with_capacity.html_safe,
          'id' => easy_room.id,
          'available' => easy_room.available_for_date?(easy_meeting.start_time, easy_meeting.end_time, easy_meeting.id), }
      ]

      get :index, params: { autocomplete_action: 'room_availability_for_date_time',
                            format: :json,
                            start_time: easy_meeting.start_time,
                            end_time: easy_meeting.end_time,
                            easy_meeting_id: easy_meeting.id,
                            term: easy_room.name, }

      parsed_response = JSON.parse(response.body)
      expect(parsed_response).to eq(expected_result)
    end
  end
end
