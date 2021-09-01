require 'easy_extensions/spec_helper'

describe EasyRoomsController do

  render_views

  let(:room) {FactoryGirl.create(:easy_room)}

  context 'with admin user', logged: :admin do
    describe 'GET new' do
      it 'returns a new form' do
        get :new
        expect( response.body ).to have_selector('form#new_easy_room')
      end
    end

    describe 'POST create' do
      it 'creates a room if attributes are valid' do
        room_attrs = FactoryGirl.attributes_for(:easy_room)
        expect {post :create, :params => {easy_room: room_attrs}}.to change(EasyRoom, :count).by(1)
        new_room = assigns(:easy_room).reload
        expect( new_room.name ).to eq( room_attrs[:name] )
        expect( new_room.capacity ).to eq( room_attrs[:capacity] )
      end

      it 'renders validation errors if attributes are not valid' do
        room_attrs = FactoryGirl.attributes_for(:easy_room)
        room_attrs[:name] = ''
        expect {post :create, :params => {easy_room: room_attrs}}.not_to change(EasyRoom, :count)
        expect( response.body ).to have_selector('#errorExplanation', text: "Name cannot be blank")
      end
    end

    describe 'GET edit' do
      it 'returns a new form' do
        get :edit, :params => {id: room.id}
        expect( response.body ).to have_css("form#edit_easy_room_#{room.id}")
      end
    end

    describe 'PUT update' do
      it 'updates a room if attributes are valid' do
        old_name = room.name
        new_name = 'New name'
        expect {
          put :update, :params => {id: room.id, easy_room: {name: new_name}}
          room.reload
        }.to change{room.name}.from(old_name).to(new_name)
      end

      it 'renders validation errors if attributes are invalid' do
        expect {
          put :update, :params => {id: room.id, easy_room: {name: ''}}
          room.reload
        }.to_not change{[room.name, room.capacity]}
        expect( response.body ).to have_selector('#errorExplanation', text: "Name cannot be blank")
      end
    end

    describe 'DELETE destroy' do
      it 'destroys the room' do
        room
        expect {
          delete :destroy, :params => {id: room}
        }.to change{EasyRoom.count}.by(-1)
      end
    end

  end

end
