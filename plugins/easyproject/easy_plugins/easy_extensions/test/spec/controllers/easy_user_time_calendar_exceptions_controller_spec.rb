require 'easy_extensions/spec_helper'

describe EasyUserTimeCalendarExceptionsController, logged: :admin do
  
  render_views
  
  describe 'API' do
    let(:euwtc) { FactoryBot.create(:easy_user_time_calendar) }
    let(:eutce) { FactoryBot.create(:easy_user_time_calendar_exception, calendar: euwtc) }
    let(:euwtc1) { FactoryBot.create(:easy_user_time_calendar) }
    let(:eutce1) { FactoryBot.create(:easy_user_time_calendar_exception, calendar: euwtc1) }

    context '/index' do
      it 'returns all exceptions' do
        get :index, params: { format: 'json' }
        expect(response).to be_successful
      end
    end

    context '/exceptions_from_calendar' do
      it 'returns one calendar exceptions' do
        get :exceptions_from_calendar, params: { calendar_id: eutce.calendar_id, format: 'json' }
        expect(response).to be_successful
      end
    end

    context '/show' do
      it 'returns successful request' do
        get :show, params: { id: eutce.id, format: 'json' }
        expect(response).to be_successful
      end
    end

    context '/create' do
      it 'returns successful request' do
        expect {
          post :create, params: { easy_user_time_calendar_exception: { calendar_id: euwtc.id, exception_date: Date.today, working_hours: 11 }, format: 'json' }
        }.to change(EasyUserTimeCalendarException, :count).by(1)
        expect(response).to be_successful
      end
    end

    context '/update' do
      it 'updates working hours' do
        new_working_hours = 11
        put :update, params: { id: eutce.id, easy_user_time_calendar_exception: { working_hours: new_working_hours }, format: 'json' }
        expect(response).to be_successful
        expect(eutce.reload.working_hours).to eq new_working_hours
      end
    end

    context '/delete' do
      it 'removes exception' do
        eutce
        expect {
          delete :destroy, params: { id: eutce.id, format: 'json' }
        }.to change(EasyUserTimeCalendarException, :count).by(-1)
        expect(response).to be_successful
      end
    end
  end

end
