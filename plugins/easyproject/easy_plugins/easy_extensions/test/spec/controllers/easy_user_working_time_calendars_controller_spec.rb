require 'easy_extensions/spec_helper'

describe EasyUserWorkingTimeCalendarsController, :logged => :admin do
  let(:wc) { FactoryGirl.create(:easy_user_time_calendar) }

  it 'valid exceptions' do
    post :mass_exceptions, :params => { :id => wc, :mass_exception => { :from => Date.today, :to => Date.today + 1, :working_hours => 8, :back_url => '/' } }
    expect(response).not_to have_http_status(500)
  end

  it 'exceptions without from/to/back_url/params' do
    post :mass_exceptions, :params => { :id => wc, :mass_exception => { :to => Date.today + 1, :working_hours => 8, :back_url => '/' } }
    expect(response).not_to have_http_status(500)

    post :mass_exceptions, :params => { :id => wc, :mass_exception => { :from => Date.today, :working_hours => 8, :back_url => '/' } }
    expect(response).not_to have_http_status(500)

    post :mass_exceptions, :params => { :id => wc, :mass_exception => { :from => Date.today, :to => Date.today + 1, :working_hours => 8 } }
    expect(response).not_to have_http_status(500)

    post :mass_exceptions, :params => { :id => wc }
    expect(response).not_to have_http_status(500)
  end

  describe 'API' do
    let(:euwtc) { FactoryBot.create(:easy_user_time_calendar) }
    let(:euwtc_attributes) { FactoryBot.attributes_for(:easy_user_time_calendar) }

    context '/index' do
      it 'returns successful request' do
        euwtc
        get :index, params: { format: 'json' }
        expect(response).to be_successful
      end
    end

    context '/show' do
      it 'returns successful request' do
        get :show, params: { id: euwtc.id, format: 'json' }
        expect(response).to be_successful
      end
    end

    context '/create' do
      it 'returns successful request' do
        expect {
          post :create, params: { easy_user_working_time_calendar: euwtc_attributes, format: 'json' }
        }.to change(EasyUserWorkingTimeCalendar, :count).by(1)
        expect(response).to be_successful
      end
    end

    context '/update' do
      it 'updates name' do
        new_name = 'Updated calendar'
        put :update, params: { id: euwtc.id, easy_user_working_time_calendar: { name: new_name }, format: 'json' }
        expect(response).to be_successful
        expect(euwtc.reload.name).to eq new_name
      end
    end

    context '/delete' do
      it 'removes calendar' do
        euwtc
        expect {
          delete :destroy, params: { id: euwtc.id, format: 'json' }
        }.to change(EasyUserWorkingTimeCalendar, :count).by(-1)
        expect(response).to be_successful
      end
    end

    context '/assign_to_user' do
      it 'assigns calendar to user' do
        euwtc
        post :assign_to_user, params: { working_time_calendar: euwtc.id, user_id: User.current.id, format: 'json' }
        expect(response).to be_successful
        assigned_calendar = EasyUserWorkingTimeCalendar.find_by_user(User.current)
        expect(assigned_calendar&.name).to eq euwtc.name
      end
    end
  end

end
