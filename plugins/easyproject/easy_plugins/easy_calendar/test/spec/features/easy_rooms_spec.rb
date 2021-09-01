require 'easy_extensions/spec_helper'

feature 'easy rooms', js: true, logged: :admin do
  let(:room) {FactoryGirl.create(:easy_room)}

  scenario 'new room' do
    visit new_easy_room_path
    expect(page).to have_css('#easy_room_name')
  end

  scenario 'preselect room' do
    room
    visit availability_easy_rooms_path
    wait_for_ajax
    page.find('tr.fc-slot0').click
    wait_for_ajax
    expect(page.find('#easy_meeting_easy_room_id', visible: false).value).to eq(room.id.to_s)
  end
end
