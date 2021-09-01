require 'easy_extensions/spec_helper'

describe EasyTimesheetsController do
  context 'with admin user', logged: :admin do

    let(:time_entry) { FactoryBot.create(:time_entry, user: User.current) }
    let(:time_sheet) { EasyTimesheet.create(start_date: Date.today, end_date: Date.today.end_of_week, user_id: User.current.id) }

    describe 'GETs' do
      it 'get index and response all ok' do
        get :index
        expect(response).to be_successful
        expect(response.status).to eq(200)
      end

      it 'show easy time sheet' do
        with_easy_settings(easy_timesheets_enabled_timesheet_calendar: 'week') do
          get :show, params: { id: time_sheet.id }
        end
        expect(response.status).to eq(200)
      end
    end
  end

  context 'with regular user', logged: true do
    describe 'GETs' do
      it 'get index and response all ok' do
        get :index
        expect(response.status).to eq(403)

        role = Role.non_member
        role.add_permission!(:view_easy_timesheets)
        role.reload
        User.current.reload
        get :index
        expect(response.status).to eq(200)
      end
    end
  end

  context 'monthly', logged: true do
    before :each do
      Role.non_member.add_permission! :log_time, :view_time_entries
    end

    let(:time_sheet) { double(EasyTimesheet, start_date: Date.new(2018, 11, 1), end_date: Date.new(2018, 11, 30), previous: nil, next: nil, copy_rows_from: nil) }

    it 'default settings - monthly' do
      with_easy_settings(easy_timesheets_enabled_timesheet_calendar: nil) do
        get :monthly_new
        expect(assigns(:easy_timesheet)).not_to be_nil

        get :new
        expect(response).to have_http_status(403)
      end
    end

    it '#monthly_create' do
      with_easy_settings(easy_timesheets_enabled_timesheet_calendar: 'month') do
        post :monthly_create, params: { easy_timesheet: { start_date: '2018-11-01' } }
        expect(assigns(:easy_timesheet)).not_to be_nil
      end
      with_easy_settings(easy_timesheets_enabled_timesheet_calendar: 'week') do
        post :monthly_create, params: { easy_timesheet: { start_date: '2018-11-01' } }
        expect(response).to have_http_status(403)
        # to avoid stub chain of methods
        allow(controller).to receive(:create)
        post :create, params: { easy_timesheet: { start_date: '2018-11-01' } }
        expect(response).not_to have_http_status(403)
      end
    end

    it '#monthly_new' do
      with_easy_settings(easy_timesheets_enabled_timesheet_calendar: 'month') do
        get :monthly_new
        expect(assigns(:easy_timesheet)).not_to be_nil
      end

      with_easy_settings(easy_timesheets_enabled_timesheet_calendar: 'week') do
        post :monthly_new
        expect(response).to have_http_status(403)
        # to avoid stub chain of methods
        allow(controller).to receive(:new)
        post :new
        expect(response).not_to have_http_status(403)
      end
    end

    it '#monthly_show' do
      allow(EasyTimesheet).to receive(:monthly).and_return(EasyTimesheet)
      allow(EasyTimesheet).to receive(:visible).and_return(EasyTimesheet)
      allow(EasyTimesheet).to receive(:find).and_return(time_sheet)
      with_easy_settings(easy_timesheets_enabled_timesheet_calendar: 'month') do
        get :monthly_show, params: { id: 22 }
        expect(assigns(:day_range)).to eq time_sheet.start_date..time_sheet.end_date
        expect(assigns(:easy_timesheet)).to eq time_sheet
      end

      with_easy_settings(easy_timesheets_enabled_timesheet_calendar: 'week') do
        post :monthly_show, params: { id: 22 }
        expect(response).to have_http_status(403)

        post :show, params: { id: 22 }
        expect(assigns(:day_range)).to eq time_sheet.start_date..time_sheet.end_date
        expect(assigns(:easy_timesheet)).to eq time_sheet
      end
    end
  end

end
