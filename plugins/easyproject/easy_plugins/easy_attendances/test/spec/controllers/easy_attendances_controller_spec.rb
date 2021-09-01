require 'easy_extensions/spec_helper'

describe EasyAttendancesController, logged: :admin do
  include EasyAttendancesHelper

  def l(lang_key) # I18n hack
    I18n.t(lang_key)
  end

  let!(:default_activity) { FactoryGirl.create(:easy_attendance_activity, {:is_default => true}) }
  let(:activity_without_specify_time) { FactoryGirl.create(:easy_attendance_activity, use_specify_time: false, at_work: true) }
  let(:users) { FactoryGirl.create_list(:user, 3) }
  let!(:vacation_activity)  { FactoryGirl.create(:vacation_easy_attendance_activity, :approval_required => false) }
  let(:easy_attendance_params) {
    attributes = FactoryGirl.attributes_for(:full_day_easy_attendance)
    attributes[:user_id] = User.current.id
    attributes[:easy_attendance_activity_id] = vacation_activity.id
    attributes
  }
  let(:easy_attendance_half_day_params) {
    attributes = FactoryGirl.attributes_for(:half_day_easy_attendance)
    attributes[:user_id] = User.current.id
    attributes[:easy_attendance_activity_id] = vacation_activity.id
    attributes
  }
  let(:easy_attendance_weekend_vacation_params) {
    attributes = FactoryGirl.attributes_for(:full_day_easy_attendance)
    attributes[:user_id] = User.current.id
    attributes[:easy_attendance_activity_id] = vacation_activity.id
    attributes[:arrival] = Date.new(2016, 1, 16).to_time + 7.hours
    attributes[:departure] = attributes[:arrival] + 5.hours
    attributes
  }
  let(:user_work_attendance) {
    attendance = FactoryGirl.build(:afternoon_easy_attendance)
    attendance.easy_attendance_activity = FactoryGirl.create(:easy_attendance_activity)
    attendance.user = User.current
    attendance.save
    attendance
  }
  let(:user_vacation_attendance) {
    attendance = FactoryGirl.build(:afternoon_easy_attendance)
    attendance.easy_attendance_activity = FactoryGirl.create(:vacation_easy_attendance_activity)
    attendance.user = User.current
    attendance.save
    attendance
  }
  let(:time_now) {
    Time.parse("2014-11-24 15:26:26")
  }
  let(:prepare_work_time) {
    user = User.current
    user.current_working_time_calendar.time_to = Time.parse("2007-01-31 17:30:00")
    user.save
  }
  let(:prepare_non_work_time) {
    user = User.current
    user.current_working_time_calendar.time_to = Time.parse("2007-01-31 17:30:00")
    user.save
  }
  let(:status) { 403 }

  describe 'GET index' do
    render_views

    it 'success with invalid office range setting' do
      with_settings(:plugin_easy_attendances => {'office_ip_range' => 'ff'}) do
        get :index
        expect(response).to be_successful
      end
    end

    it 'visit index with grouped queries' do
      get :index, params: {tab: 'list', load_groups_opened: true, group_by: 'easy_attendance_activity', arrival: 'to_today', set_filter: 1}
      expect(response).to be_successful
    end

    it 'visit calendar with grouped queries' do
      get :index, params: {tab: 'calendar', group_by: 'easy_attendance_activity', set_filter: 1}
      expect(response).to be_successful
    end

    it 'load grouped records by time column' do
      with_time_travel(0) do
        att = FactoryGirl.create_list(:easy_attendance, 2)
        get :index, params: {tab: 'list', group_by: 'created_at', group_to_load: "#{att[0].created_at.to_date}+00:00:00", set_filter: 1}, xhr: true
      end

      expect(response).to be_successful
      expect(assigns(:entities).count).to eq(2)
    end

    context 'when query selected' do
      context 'when Calendar tab selected' do
        let(:attendance_query) { FactoryGirl.create(:easy_attendance_query) }
        render_views

        it 'renders calendar' do
          get :index, :params => {:tab => 'calendar', :query_id => attendance_query}

          expect(response).to render_template(:partial => 'common/_calendar')
        end
      end
    end

  end

  describe 'GET show' do
    context 'html format' do
      subject { get :show, params: { id: user_work_attendance, format: :html } }
      it 'success' do
        expect(subject).to be_successful
        expect(assigns(:easy_attendance)).to eq(user_work_attendance)
        expect(subject).to render_template('easy_attendances/show')
      end
    end

    context 'json format' do
      subject { get :show, params: { id: user_work_attendance, format: :json } }
      it 'success' do
        expect(subject).to be_successful
        expect(assigns(:easy_attendance)).to eq(user_work_attendance)
        expect(subject).to render_template('easy_attendances/show')
      end
    end
  end

  describe 'GET #statuses' do
    render_views

    it 'returns statuses for all requested users' do
      user_ids = users.collect{|u| u.id }

      get :statuses, :params => {user_ids: user_ids}

      expect(json.keys).to match_array(user_ids.collect{|id| id.to_s.to_sym})
      expect(json[user_ids.first.to_s.to_sym]).to match(/user easy-attendance-indicator/)
    end

  end

  describe 'POST correct attendance' do

    it 'creates vacation attendance' do
      expect{
        post :create, :params => {
          :easy_attendance => easy_attendance_params
        }
      }.to change(EasyAttendance.joins(:easy_attendance_activity).where(:easy_attendance_activities => {:at_work => false}), :count)
    end

  end

  describe 'POST uncorrect attendance' do
    before {
      limit = User.current.easy_attendance_activity_user_limits.build(:easy_attendance_activity_id => vacation_activity.id)
      limit.days = 0.0
      limit.save
    }

    it 'fails when no activity defined' do
      EasyAttendanceActivity.where(:is_default => true).update_all(:is_default => false)
      expect(EasyAttendanceActivity.default).to be nil
      expect{
        post :create, :params => {
          :easy_attendance => easy_attendance_params.merge(:easy_attendance_activity_id => nil)
        }
      }.to change(EasyAttendance, :count).by(0)
    end

    it 'fails when user does not exist' do
      expect{
        post :create, :params => {
          :easy_attendance => easy_attendance_params.merge(:user_id => User.last.id + 1)
        }
      }.to change(EasyAttendance.joins(:easy_attendance_activity).where(:easy_attendance_activities => {:at_work => false}), :count).by(0)
    end

  end

  describe 'POST correct half day attendance' do
    before {
      limit = User.current.easy_attendance_activity_user_limits.build(:easy_attendance_activity_id => vacation_activity.id)
      limit.days = 4.0
      limit.save
    }

    it 'creates half day attendance' do
      expect{
        post :create, :params => {
          :easy_attendance => easy_attendance_half_day_params
        }
      }.to change(EasyAttendance.joins(:easy_attendance_activity).where(:easy_attendance_activities => {:at_work => false}), :count).by(1)

      arrival_year = easy_attendance_half_day_params[:arrival].year
      eaaul = User.current.easy_attendance_activity_user_limits.where(:easy_attendance_activity_id => vacation_activity.id).first
      expect( eaaul.limit_days_difference_per_year(arrival_year) ).to eq( 3.5 )
    end
  end

  describe 'logged user' do
    it 'should have status online' do
      with_user_pref('last_easy_attendance_arrival_date' => nil) do
        prepare_work_time

        with_time_travel(0, :now => time_now) do
          get :index
          expect( User.current.current_attendance ).not_to be_nil

          expect( easy_attendance_indicator(User.current).last ).to include('online')
        end
      end
    end
  end

  describe 'not logged user' do
    it 'should have status offline' do
      logged_user(users.first)
      expect( easy_attendance_indicator(users.last).last ).to include('offline')
    end

    it 'should display vacation if last attendance is not work' do
      logged_user(users.first)
      a = user_vacation_attendance
      logged_user(users.last)

      with_time_travel(1.hour, :now => a.arrival) do
        expect(easy_attendance_indicator(a.user).first ).to include(a.easy_attendance_activity.name)
        expect(easy_attendance_indicator(a.user).last ).to include('offline')
      end
    end

    it 'should be online if last attendance is work' do
      logged_user(users.first)
      a = user_work_attendance
      logged_user(users.last)

      with_time_travel(1.hour, :now => a.arrival) do
        expect( easy_attendance_indicator(a.user).first ).to include(a.easy_attendance_activity.name)
        expect( easy_attendance_indicator(a.user).last ).to include('online')
      end
    end

    it 'should be offline if last attendance is working activity and user is offline' do
      logged_user(users.first)
      a = user_work_attendance
      logged_user(users.last)

      a.departure = a.arrival + 8.hour
      with_time_travel(1.hour, :now => a.departure) do
        expect( easy_attendance_indicator(a.user).first ).not_to include(a.easy_attendance_activity.name)
        expect( easy_attendance_indicator(a.user).last ).to include('offline')
      end
    end

    context 'approval' do
      def create_attendance(approval_status)
        activity = FactoryBot.create(:easy_attendance_activity, approval_required: true)
        FactoryBot.create(:afternoon_easy_attendance, user: User.current, easy_attendance_activity: activity, approval_status: approval_status)
      end

      it 'should display offline if last attendance is rejected' do
        logged_user(users.first)
        a = create_attendance(EasyAttendance::APPROVAL_REJECTED)
        logged_user(users.last)

        with_time_travel(1.hour, now: a.arrival) do
          expect( easy_attendance_indicator(a.user).first ).not_to include(a.easy_attendance_activity.name)
          expect( easy_attendance_indicator(a.user).last ).to include('offline')
        end
      end

      it 'should display online if last attendance is approved' do
        logged_user(users.first)
        a = create_attendance(EasyAttendance::APPROVAL_APPROVED)
        logged_user(users.last)

        with_time_travel(1.hour, now: a.arrival) do
          expect( easy_attendance_indicator(a.user).first ).to include(a.easy_attendance_activity.name)
          expect( easy_attendance_indicator(a.user).last ).to include('online')
        end
      end
    end
  end

  describe 'time is not in_work_time?' do
    it 'attendance should not be created' do
      prepare_non_work_time

      with_time_travel(0, :now => time_now) do
        expect {
          get :index
        }.to change(EasyAttendance, :count).by(0)
      end
    end

    it 'one day creation should pass' do
      # The date is on weekend
      params = {
        arrival: Date.new(2019, 5, 25),
        departure: Date.new(2019, 5, 25),
        easy_attendance: {
          range: EasyAttendance::RANGE_FULL_DAY,
          user_id: User.current.id,
          easy_attendance_activity_id: activity_without_specify_time.id
        }
      }

      # Just to be sure
      expect(User.current.current_working_time_calendar.working_hours(params[:arrival])).to eq(0)

      expect {
        post :create, params: params
      }.to change(EasyAttendance, :count).by(1)
    end
  end

  describe 'time is in_work_time?' do
    it 'attendance should be created' do
      with_user_pref('last_easy_attendance_arrival_date' => nil) do
        prepare_work_time

        with_time_travel(0, :now => time_now) do
          expect {
            get :index
          }.to change(EasyAttendance, :count).by(1)
        end
      end
    end

    it 'multiple day should fail' do
      # Dates are on weekend
      params = {
        arrival: Date.new(2019, 5, 25),
        departure: Date.new(2019, 5, 26),
        easy_attendance: {
          range: EasyAttendance::RANGE_FULL_DAY,
          user_id: User.current.id,
          easy_attendance_activity_id: activity_without_specify_time.id
        }
      }

      # Just to be sure
      expect(User.current.current_working_time_calendar.working_hours(params[:arrival])).to eq(0)
      expect(User.current.current_working_time_calendar.working_hours(params[:departure])).to eq(0)

      expect {
        post :create, params: params
      }.to change(EasyAttendance, :count).by(0)
    end
  end

  describe 'POST cancel request' do
    let(:member) { FactoryGirl.create(:member, :user => User.current)}
    let(:approved_vacation_attendance) { FactoryGirl.create(:vacation_easy_attendance, :user => member.user) }
    let(:waiting_vacation_attendance) { FactoryGirl.create(:vacation_easy_attendance, :approval_status => EasyAttendance::APPROVAL_WAITING, :user => member.user) }

    context 'when attendance is approved' do
      context 'when canceled by user without approval permission', :logged => true do
        it 'changes approval status to CANCEL_WAITING' do
          member.member_roles.first.role.remove_permission!(:edit_easy_attendance_approval)
          User.current.reload
          post :bulk_cancel, :params => {:ids => [approved_vacation_attendance.id]}

          updated_attendance = EasyAttendance.find(approved_vacation_attendance.id)

          expect(updated_attendance.approval_status).to eq(EasyAttendance::CANCEL_WAITING)
        end
      end

      context 'when canceled by admin' do
        it 'is canceled directly' do
          expect_direct_cancel(approved_vacation_attendance)
        end
      end
    end

    context 'when attendance is waiting for approval', :logged => true do
      it 'is canceled directly' do
        expect_direct_cancel(waiting_vacation_attendance)
      end
    end

    def expect_direct_cancel(attendance)
      User.current.reload
      post :bulk_cancel, :params => {:ids => [attendance.id]}
      updated_attendance = EasyAttendance.find(attendance.id)

      expect(updated_attendance.approval_status).to eq(EasyAttendance::CANCEL_APPROVED)
    end
  end

  describe 'POST approval_save', logged: :admin do
    let(:waiting_vacation_attendance) { double('EasyAttendance', id: 42) }

    context 'JSON requests' do

      def prepare_and_make_request(returned_attendances)
        approve_params = { ids: [waiting_vacation_attendance.id.to_s], approve: '1', notes: 'Approve!!' }
        expect(EasyAttendance).to receive(:approve_attendances).with(*approve_params.values)
                                                               .and_return(returned_attendances)
        post :approval_save, params: approve_params.merge(format: :json)
      end

      it 'returns updated attendances ids' do
        prepare_and_make_request(saved: [waiting_vacation_attendance], unsaved: [])

        expect(response.body).to eq({ updated_untity_ids: [waiting_vacation_attendance.id] }.to_json)
        expect(response).to have_http_status(:success)
      end

      context 'when unsaved attendances exist' do
        it 'calls render_api_errors with correct error messages' do
          expect(waiting_vacation_attendance).to receive(:errors).and_return(double(full_messages: 'Error!!'))
          expect(controller).to receive(:render_api_errors).with(['Error!!'])

          prepare_and_make_request(saved: [], unsaved: [waiting_vacation_attendance])
        end
      end

      context 'when unsaved attendances do not exit' do
        it 'calls render_api_errors with correct error messages' do
          allow(I18n).to receive(:t).and_return('Six by nine. Forty two.')
          expect(controller).to receive(:render_api_errors).with(['Six by nine. Forty two.'])

          prepare_and_make_request(saved: [], unsaved: [])
        end
      end

    end
  end

  describe 'POST change_activity' do
    context 'when no activity selected' do
      it 'should render easy_attendances/change_activity template' do
        post :change_activity, params: { preselected_departure_date: '2018-10-10', format: :js }
        expect(response).to render_template('easy_attendances/change_activity')
      end
    end
  end

  context 'EXPORTS' do
    render_views

    it 'exports to xlsx' do
      get :index, params: { format: 'xlsx', set_filter: '0', easy_query: { columns_to_export: 'all' }, tab: 'list' }
      expect( response ).to be_successful
      expect( response.content_type ).to eq( 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' )
    end

    it 'exports to xlsx without an active tab' do
      get :index, params: { format: 'xlsx' }
      expect( response ).to be_successful
      expect( response.content_type ).to eq( 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' )
    end

    it 'exports to csv' do
      get :index, params: { format: 'csv', set_filter: '1', column_names: ['user'] }
      expect( response ).to be_successful
      expect( response.content_type ).to include('text/csv')
      expect( response.body ).to include(I18n.t(:field_user))
    end

    it 'exports detailed report to xlsx' do
      get :detailed_report, params: { format: 'xlsx', set_filter: '0', easy_query: { columns_to_export: 'all' } }
      expect( response ).to be_successful
      expect( response.content_type ).to eq( 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' )
    end

  end

  describe 'new attendance form' do
    render_views

    let(:external_easy_user_type) { FactoryGirl.create(:easy_user_type, :internal => false) }
    let(:external_user) { FactoryGirl.create(:admin_user, :easy_user_type => external_easy_user_type) }

    it 'admin' do
      get :new
      expect(response).to be_successful
    end

    it 'external user' do
      logged_user(external_user)
      get :new
      expect(response).to be_successful
    end

  end

  describe 'user without permission to use attendance', :logged => true do
    it 'cannot create attendance' do
      get :new
      expect(response).to have_http_status(status)

      post :create, :params => {:easy_attendance => easy_attendance_params}
      expect(response).to have_http_status(status)
    end

    it 'cannot set arrival or departure' do
      get :arrival, :xhr => true
      expect(response).to have_http_status(status)

      get :departure, :params => {:id => user_work_attendance.id}
      expect(response).to have_http_status(status)
    end

    it 'cannot edit attendance' do
      get :edit, :params => {:id => user_work_attendance.id}
      expect(response).to have_http_status(status)

      put :update, :params => {:id => user_work_attendance.id}
      expect(response).to have_http_status(status)
    end

    it 'cannot destroy attendance' do
      delete :destroy, :params => {:id => user_work_attendance.id}
      expect(response).to have_http_status(status)
    end
   end

  describe 'user with permission', :logged => true do
    let!(:member) { FactoryBot.create(:member, :user => User.current) }
    let(:user) { FactoryBot.create(:user) }
    before(:each) { User.current.reload }

    it 'journalize attendance' do
      expect {
        put :update, params: {id: user_work_attendance.id, easy_attendance: {user_id: user.id}, format: 'json'}
      }.to change(Journal, :count).by(1)
      expect(user_work_attendance.reload.journals.first.details.map(&:prop_key)).to include('user_id')
    end

    it 'can create attendance' do
      get :new
      expect(response).not_to have_http_status(status)

      post :create, :params => {:easy_attendance => easy_attendance_params}
      expect(response).not_to have_http_status(status)
    end

    it 'can bulk create attendance' do
      user
      expect{
        post :create, params: {easy_attendance: easy_attendance_params.merge(user_id: [User.current.id, user.id]), format: 'json'}
      }.to change(EasyAttendance, :count).by(2)
      expect(response).to have_http_status(200)
      post :create, params: {easy_attendance: easy_attendance_params.merge(user_id: [User.current.id, user.id]), format: 'json'}
      expect(response).to have_http_status(422)
    end

    it 'can edit attendance' do
      get :edit, :params => {:id => user_work_attendance.id}
      expect(response).not_to have_http_status(status)

      put :update, :params => {:id => user_work_attendance.id}
      expect(response).not_to have_http_status(status)
    end

    it 'can destroy attendance' do
      delete :destroy, :params => {:id => user_work_attendance.id}
      expect(response).not_to have_http_status(status)
    end
  end

  describe 'report', :logged => true do
    render_views

    it 'show report' do
      role = Role.non_member
      role.add_permission! :view_easy_attendances
      User.current.reload
      get :report
      expect(response).to be_successful
      expect(assigns[:reports].size).to eq(1)
    end
  end

  describe 'without user', :logged => :admin do
    render_views

    let(:easy_attendance) { FactoryGirl.create(:easy_attendance) }

    it 'calendar' do
      easy_attendance.user.delete
      get :index, :params => {:start_date => easy_attendance.arrival.to_date.to_s, :tab => 'calendar', :set_filter => '1'}
      expect(response).to be_successful
    end

    it 'edit' do
      easy_attendance.user.delete
      get :edit, :params => {:id => easy_attendance}
      expect(response).to be_successful
    end

    it 'delete' do
      easy_attendance.user.delete
      delete :destroy, :params => {:id => easy_attendance}
      expect(response).to redirect_to easy_attendances_path
    end
  end

  context 'EasyEage rendering actions' do
    let(:easy_page) { double(EasyPage, user: nil, editable?: true) }

    before :each do
      controller.instance_variable_set(:@page, easy_page)
    end

    describe '#overview' do
      it do
        expect(controller).to receive(:allowed_to_page_show?).and_return(true)
        get :overview
        expect(response).to be_successful
      end
    end

    describe '#layout' do
      it do
        get :layout
        expect(response).to be_successful
      end
    end
  end

  describe '#index' do
    it 'with mobile and api' do
      allow(controller).to receive(:in_mobile_view?).and_return(true)
      get :index, params: { format: :json}
      expect(assigns[:entity_count]).to eq(0)
    end

    it 'without select output' do
      allow_any_instance_of(EasyAttendanceQuery).to receive(:new_record?).and_return(false)
      get :index
      expect(assigns[:query].outputs).to eq(['list'])
    end
  end

  it '#report' do
    role = Role.non_member
    role.add_permission! :view_easy_attendance_other_users
    group = FactoryBot.create(:group, users: [User.current])
    get :report, params: { report: { users: [User.current.id, group.id] }}
    expect(assigns[:selected_user_ids]).to eq([User.current.id])
  end

  it '#departure' do
    user_work_attendance.update_columns(arrival: (Time.now-5.hours), departure: nil)

    get :departure, params: { id: user_work_attendance.id }
    expect(response).to redirect_to(easy_attendances_path)

    user_work_attendance.reload
    expect(user_work_attendance.departure).not_to be_nil
  end

  context 'detailed report' do
    render_views

    it 'quarter zoom' do
      get :detailed_report, params: {set_filter: '1', period_zoom: 'quarter'}
      expect(response).to be_successful
    end

    context 'saved query period' do
      let(:saved_query) { FactoryBot.create(:easy_attendance_user_query, period_date_period_type: '1', period_date_period: 'today', period_zoom: 'week', period_start_date: Date.new(2020,01,01), period_end_date: Date.new(2020,01,01)) }
      let(:saved_query2) { FactoryBot.create(:easy_attendance_user_query, period_date_period_type: '1', period_date_period: 'yesterday', period_zoom: 'week', period_start_date: Date.new(2020,01,01), period_end_date: Date.new(2020,01,01)) }

      it 'today' do
        get :detailed_report, params: {query_id: saved_query.id}
        expect(response).to be_successful
        expect(assigns[:query].period_start_date).to eq(User.current.today)
      end

      context 'yesterday' do
        it 'with default settings' do
          with_easy_settings("easy_attendance_user_query_period_date_period" => 'tomorrow', "easy_attendance_user_query_period_date_period_type" => '1') do
            get :detailed_report, params: {query_id: saved_query2.id}
            expect(response).to be_successful
            expect(assigns[:query].period_start_date).to eq(User.current.today - 1.day)
          end
        end

        it 'without default settings' do
          get :detailed_report, params: {query_id: saved_query2.id}
          expect(response).to be_successful
          expect(assigns[:query].period_start_date).to eq(User.current.today - 1.day)
        end
      end

      it 'default settings' do
        with_easy_settings("easy_attendance_user_query_period_date_period" => 'tomorrow', "easy_attendance_user_query_period_date_period_type" => '1') do
          get :detailed_report
          expect(response).to be_successful
          expect(assigns[:query].period_start_date).to eq(User.current.today + 1.day)
        end
      end
    end

    context 'week periods' do
      it 'day' do
        get :detailed_report, params: {set_filter: '1', period_zoom: 'week', period_start_date: Date.new(2020,01,01), period_end_date: Date.new(2020,01,01), column_names: ['periodic_work_time']}
        expect(response).to be_successful
        expect(assigns[:query].generated_period_columns.count).to eq(1)
      end

      it '28 days' do
        get :detailed_report, params: {set_filter: '1', period_zoom: 'week', period_start_date: Date.new(2020,01,01), period_end_date: Date.new(2020,01,28), column_names: ['periodic_work_time']}
        expect(response).to be_successful
        expect(assigns[:query].generated_period_columns.count).to eq(5)
      end

      it 'month' do
        get :detailed_report, params: {set_filter: '1', period_zoom: 'week', period_start_date: Date.new(2020,01,01), period_end_date: Date.new(2020,01,31), column_names: ['periodic_work_time']}
        expect(response).to be_successful
        expect(assigns[:query].generated_period_columns.count).to eq(5)
      end
    end
  end

  context 'without departure' do
    it '#edit' do
      allow(Time).to receive(:now).and_return(Time.parse('2019-03-18 20:45:00'))
      attendance = FactoryBot.create(:easy_attendance, departure: nil, arrival: Time.parse('2019-03-18 17:30:00'))
      get :edit, params: { id: attendance.id }
      expect(assigns[:easy_attendance].departure).to eq(Time.parse('2019-03-18 19:45:00'))
    end
  end

  context 'bulk actions' do
    let(:easy_attendance) { FactoryBot.create(:easy_attendance) }
    it '#bulk_update' do
      activity = FactoryBot.create(:easy_attendance_activity)
      put :bulk_update, params: {
        ids: [user_work_attendance.id, easy_attendance.id],
        easy_attendance: { easy_attendance_activity_id: activity.id }
      }
      expect(assigns[:easy_attendances].pluck(:easy_attendance_activity_id).uniq).to eq([activity.id])
    end

    it '#bulk_destroy' do
      user_work_attendance
      easy_attendance
      expect { delete :bulk_destroy, params: { ids: [user_work_attendance.id, easy_attendance.id] } }.
        to change(EasyAttendance, :count).from(2).to(0)
    end
  end

  it '#new_notify_after_arrived' do
    EasyAttendanceUserArrivalNotify.create(user_id: User.current.id, notify_to_id: User.current.id)
    get :new_notify_after_arrived, params: { user_id: User.current.id }
    expect(assigns[:easy_attendance_notify_count]).to eq(1)
  end

  it '#create_notify_after_arrived' do
    expect { post :create_notify_after_arrived, params: { user_id: User.current.id } }.
      to change(EasyAttendanceUserArrivalNotify, :count).by(1)
  end

  it '#approval' do
    get :approval
    expect(response).to redirect_to(easy_attendances_path(tab: 'list'))
  end

  it '#approval_save' do
    post :approval_save
    expect(response).to redirect_to(easy_attendances_path(tab: 'list'))
  end

  context 'private methods' do
    it '#find_easy_attendance' do
      get :edit, params: { id: 'xx'}
      expect(response).to have_http_status :not_found
    end

    it '#enabled_this' do
      allow(EasyExtensions::EasyProjectSettings).to receive(:easy_attendance_enabled).and_return(false)
      get :index
      expect(response).to have_http_status :forbidden
    end
  end

  context '#check_vacation_limit' do

    before(:each) do
      limit = User.current.easy_attendance_activity_user_limits.build(easy_attendance_activity_id: vacation_activity.id)

      limit.days = 1.0
      limit.save
    end

    it 'valid' do
      post :check_vacation_limit, params: {
        easy_attendance: easy_attendance_params,
        format: 'json'
      }

      expect(JSON.parse(response.body)['is_valid']).to eq(true)
    end

    it 'invalid' do
      easy_attendance_params[:departure] = easy_attendance_params[:arrival] + 2.days
      post :check_vacation_limit, params: {
        easy_attendance: easy_attendance_params,
        format: 'json'
      }

      expect(JSON.parse(response.body)['is_valid']).to eq(false)
    end
  end
end
